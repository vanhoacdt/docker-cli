#!/usr/bin/env bash
SHOW_STATS=0; FULL_PORTS=0; DEPLOY_MODE=0; IMAGE_MODE=0; OVERVIEW_MODE=0; WATCH_MODE=0; INSPECT_MODE=0; LOG_MODE=0; FOLLOW_MODE=0; NET_MODE=0; EVENTS_MODE=0; HELP_MODE=0
SORT_MODE=""; ONLY_RUNNING=1; TARGET=""; TAIL="20"

get_virtual_sizes() {
  docker ps -a -s --format '{{.Names}}	{{.Size}}' 2>/dev/null | awk -F'	' '{
    name = $1
    sz = $2
    if (match(sz, /\(virtual ([^)]+)\)/, m)) {
      print name "	" m[1]
    }
  }'
}


# === Helper phân giải đường dẫn dự án / file docker-compose.yml ===
resolve_compose_context() {
  local raw="${1:-}"
  [[ -z "$raw" ]] && return 1
  local exp="${raw/#\~/$HOME}"
  local cfile=""
  if [[ -f "$exp" ]]; then
    cfile="$(realpath "$exp")"
  elif [[ -d "$exp" ]]; then
    for cf in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
      if [[ -f "$exp/$cf" ]]; then
        cfile="$(realpath "$exp/$cf")"
        break
      fi
    done
  elif [[ "$raw" == */* || "$raw" == ~* || "$raw" == .* ]]; then
    return 1
  elif [[ -d "$HOME/docker/$raw" ]]; then
    # Chỉ ưu tiên tên thư mục ~/docker/<raw> nếu không trùng tên container cụ thể đang tồn tại
    if ! docker ps -a --format '{{.Names}}' 2>/dev/null | grep -Fxq "$raw"; then
      for cf in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
        if [[ -f "$HOME/docker/$raw/$cf" ]]; then
          cfile="$(realpath "$HOME/docker/$raw/$cf")"
          break
        fi
      done
    fi
  fi
  [[ -n "$cfile" ]] && { echo "$cfile"; return 0; }
  return 1
}

get_project_containers() {
  local cfile="$1"
  local only_run="${2:-0}"
  local filter_svc="${3:-}"
  python3 - "$cfile" "$only_run" "$filter_svc" <<'PY_PROJ'
import json, os, subprocess, sys

cfile = os.path.realpath(sys.argv[1])
pdir = os.path.dirname(cfile)
only_run = sys.argv[2] == "1"
filter_svc = sys.argv[3].strip().lower()

raw_ids = subprocess.check_output(["docker", "ps", "-aq"], text=True).split()
if not raw_ids:
    sys.exit(0)

insp = json.loads(subprocess.check_output(["docker", "inspect", *raw_ids], text=True))
matched = []
for obj in insp:
    st = obj.get("State") or {}
    if only_run and (st.get("Status") or "").lower() not in ("running", "restarting"):
        continue
    cfg = obj.get("Config") or {}
    labels = cfg.get("Labels") or {}
    wdir = labels.get("com.docker.compose.project.working_dir") or ""
    cfiles = labels.get("com.docker.compose.project.config_files") or ""
    svc = (labels.get("com.docker.compose.service") or "").lower()
    name = (obj.get("Name") or "").lstrip("/")

    cfile_list = [os.path.realpath(x.strip()) for x in cfiles.split(",") if x.strip()]
    if cfile in cfile_list or (wdir and os.path.realpath(wdir) == pdir):
        if filter_svc and filter_svc not in (svc, name.lower()):
            continue
        matched.append((name, svc))

matched.sort(key=lambda x: x[0].lower())
for name, _ in matched:
    print(name)
PY_PROJ
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) HELP_MODE=1 ;;
    -a|--all) ONLY_RUNNING=0 ;;
    -s|--stats) SHOW_STATS=1 ;;
    -p|--ports|--full-ports) FULL_PORTS=1 ;;
    -d|--deploy|--mounts) DEPLOY_MODE=1 ;;
    -i|--images) IMAGE_MODE=1 ;;
    -o|--overview) OVERVIEW_MODE=1 ;;
    -e|--events)
      EVENTS_MODE=1
      if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
        shift
        TARGET="$1"
      fi
      ;;
    -n|--net|--networks)
      NET_MODE=1
      if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
        shift
        TARGET="$1"
      fi
      ;;
    -u|--up)
      shift
      TARGET_PATH="${1:-}"
      COMPOSE_FILE=""
      PROJ_DIR=""

      if [[ -n "$TARGET_PATH" ]]; then
        # Mở rộng dấu ~ nếu người dùng truyền dạng chuỗi
        EXPANDED_PATH="${TARGET_PATH/#\~/$HOME}"
        if [[ -f "$EXPANDED_PATH" ]]; then
          COMPOSE_FILE="$(realpath "$EXPANDED_PATH")"
          PROJ_DIR="$(dirname "$COMPOSE_FILE")"
          shift
        elif [[ -d "$EXPANDED_PATH" ]]; then
          for cf in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
            if [[ -f "$EXPANDED_PATH/$cf" ]]; then
              COMPOSE_FILE="$(realpath "$EXPANDED_PATH/$cf")"
              PROJ_DIR="$(dirname "$COMPOSE_FILE")"
              shift
              break
            fi
          done
        elif [[ ! -f "docker-compose.yml" && ! -f "docker-compose.yaml" && ! -f "compose.yml" && ! -f "compose.yaml" && -d "$HOME/docker/$TARGET_PATH" ]]; then
          for cf in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
            if [[ -f "$HOME/docker/$TARGET_PATH/$cf" ]]; then
              COMPOSE_FILE="$(realpath "$HOME/docker/$TARGET_PATH/$cf")"
              PROJ_DIR="$(dirname "$COMPOSE_FILE")"
              shift
              break
            fi
          done
        fi
      fi

      if [[ -n "$COMPOSE_FILE" ]]; then
        echo ">>> Compose: $COMPOSE_FILE"
        docker compose --project-directory "$PROJ_DIR" -f "$COMPOSE_FILE" up -d "$@"
        exit $?
      fi

      docker compose up -d "$@"
      exit $?
      ;;
    -r|--restart)
      shift
      TARGET_ARG="${1:-}"
      [[ -z "$TARGET_ARG" ]] && { echo "Dùng: dps -r <tên_hoặc_#_hoặc_đường_dẫn> [service]" >&2; exit 1; }
      if CFILE="$(resolve_compose_context "$TARGET_ARG")"; then
        shift
        SVC_ARG="${1:-}"
        mapfile -t PROJ_CTRS < <(get_project_containers "$CFILE" "0" "$SVC_ARG")
        if [[ ${#PROJ_CTRS[@]} -eq 0 ]]; then
          echo "Không tìm thấy container phù hợp trong dự án: $CFILE" >&2
          exit 1
        fi
        for c in "${PROJ_CTRS[@]}"; do
          docker restart "$c" >/dev/null && echo "Đã restart: $c"
        done
        exit 0
      fi
      shift
      TARGET_R="${1:-}"
      [[ -z "$TARGET_R" ]] && { echo "Dùng: dps -r <tên_hoặc_#>" >&2; exit 1; }
      TARGET="$TARGET_R" python3 - <<'PY'
import os, subprocess
target = os.environ.get("TARGET", "").strip()
raw = subprocess.check_output(["docker", "ps", "-a", "--format", "{{.Names}}"], text=True)
names = sorted([x.strip() for x in raw.splitlines() if x.strip()], key=str.lower)
if not names: raise SystemExit("Không có container nào.")
if target.isdigit():
    idx = int(target)
    if idx < 1 or idx > len(names): raise SystemExit(f"Số thứ tự #{idx} nằm ngoài phạm vi 1..{len(names)}.")
    cname = names[idx - 1]
else:
    exact = [n for n in names if n.lower() == target.lower()]
    matches = exact or [n for n in names if target.lower() in n.lower()]
    if not matches: raise SystemExit(f"Không tìm thấy container khớp: {target}")
    cname = matches[0]
print(f"Đang khởi động lại: {cname} ...")
subprocess.run(["docker", "restart", cname], check=True)
print(f"Đã restart xong: {cname}")
PY
      exit $?
      ;;
    -k|--stop)
      shift
      TARGET_ARG="${1:-}"
      [[ -z "$TARGET_ARG" ]] && { echo "Dùng: dps -k <tên_hoặc_#_hoặc_đường_dẫn> [service]" >&2; exit 1; }
      if CFILE="$(resolve_compose_context "$TARGET_ARG")"; then
        shift
        SVC_ARG="${1:-}"
        mapfile -t PROJ_CTRS < <(get_project_containers "$CFILE" "1" "$SVC_ARG")
        if [[ ${#PROJ_CTRS[@]} -eq 0 ]]; then
          echo "Không tìm thấy container phù hợp trong dự án: $CFILE" >&2
          exit 1
        fi
        for c in "${PROJ_CTRS[@]}"; do
          docker stop "$c" >/dev/null && echo "Đã dừng: $c"
        done
        exit 0
      fi
      shift
      TARGET_K="${1:-}"
      [[ -z "$TARGET_K" ]] && { echo "Dùng: dps -k <tên_hoặc_#>" >&2; exit 1; }
      TARGET="$TARGET_K" python3 - <<'PY'
import os, subprocess
target = os.environ.get("TARGET", "").strip()
raw = subprocess.check_output(["docker", "ps", "-a", "--format", "{{.Names}}"], text=True)
names = sorted([x.strip() for x in raw.splitlines() if x.strip()], key=str.lower)
if not names: raise SystemExit("Không có container nào.")
if target.isdigit():
    idx = int(target)
    if idx < 1 or idx > len(names): raise SystemExit(f"Số thứ tự #{idx} nằm ngoài phạm vi 1..{len(names)}.")
    cname = names[idx - 1]
else:
    exact = [n for n in names if n.lower() == target.lower()]
    matches = exact or [n for n in names if target.lower() in n.lower()]
    if not matches: raise SystemExit(f"Không tìm thấy container khớp: {target}")
    cname = matches[0]
print(f"Đang dừng container: {cname} ...")
subprocess.run(["docker", "stop", cname], check=True)
print(f"Đã stop: {cname}")
PY
      exit $?
      ;;
    -m|--rm|--remove)
      shift
      TARGET_M="${1:-}"
      [[ -z "$TARGET_M" ]] && { echo "Dùng: dps -m <tên_hoặc_#>" >&2; exit 1; }
      TARGET="$TARGET_M" python3 - <<'PY'
import os, subprocess
target = os.environ.get("TARGET", "").strip()
raw = subprocess.check_output(["docker", "ps", "-a", "--format", "{{.Names}}"], text=True)
names = sorted([x.strip() for x in raw.splitlines() if x.strip()], key=str.lower)
if not names: raise SystemExit("Không có container nào.")
if target.isdigit():
    idx = int(target)
    if idx < 1 or idx > len(names): raise SystemExit(f"Số thứ tự #{idx} nằm ngoài phạm vi 1..{len(names)}.")
    cname = names[idx - 1]
else:
    exact = [n for n in names if n.lower() == target.lower()]
    matches = exact or [n for n in names if target.lower() in n.lower()]
    if not matches: raise SystemExit(f"Không tìm thấy container khớp: {target}")
    cname = matches[0]
print(f"Đang xóa container (rm -f): {cname} ...")
subprocess.run(["docker", "rm", "-f", cname], check=True)
print(f"Đã xóa: {cname}")
PY
      exit $?
      ;;
    -t|--top)
      shift
      TARGET_ARG="${1:-}"
      [[ -z "$TARGET_ARG" ]] && { echo "Dùng: dps -t <tên_hoặc_#_hoặc_đường_dẫn> [service]" >&2; exit 1; }
      if CFILE="$(resolve_compose_context "$TARGET_ARG")"; then
        shift
        SVC_ARG="${1:-}"
        mapfile -t PROJ_CTRS < <(get_project_containers "$CFILE" "1" "$SVC_ARG")
        if [[ ${#PROJ_CTRS[@]} -eq 0 ]]; then
          echo "Không tìm thấy container trong dự án: $CFILE" >&2
          exit 1
        elif [[ ${#PROJ_CTRS[@]} -gt 1 ]]; then
          echo "Dự án có nhiều container, hãy chỉ định thêm tên service:" >&2
          printf "  - %s\n" "${PROJ_CTRS[@]}" >&2
          exit 1
        fi
        set -- "${PROJ_CTRS[0]}"
      fi
      shift
      TARGET_T="${1:-}"
      [[ -z "$TARGET_T" ]] && { echo "Dùng: dps -t <tên_hoặc_#>" >&2; exit 1; }
      TARGET="$TARGET_T" python3 - <<'PY'
import os, re, shutil, subprocess

target = os.environ.get("TARGET", "").strip()
raw = subprocess.check_output(["docker", "ps", "--format", "{{.Names}}"], text=True)
names = sorted([x.strip() for x in raw.splitlines() if x.strip()], key=str.lower)
if not names: raise SystemExit("Không có container nào đang chạy.")
if target.isdigit():
    idx = int(target)
    if idx < 1 or idx > len(names): raise SystemExit(f"Số thứ tự #{idx} nằm ngoài phạm vi 1..{len(names)}.")
    cname = names[idx - 1]
else:
    exact = [n for n in names if n.lower() == target.lower()]
    matches = exact or [n for n in names if target.lower() in n.lower()]
    if not matches: raise SystemExit(f"Không tìm thấy container đang chạy khớp: {target}")
    cname = matches[0]

out = subprocess.check_output(["docker", "top", cname], text=True)
lines = [l.rstrip() for l in out.splitlines() if l.strip()]
if len(lines) <= 1:
    print(f"=== TOP: {cname} (0 processes) ===")
    raise SystemExit(0)

raw_headers = re.split(r"\s+", lines[0].strip())
col_idx = {h.upper(): i for i, h in enumerate(raw_headers)}
rows = []
for i, ln in enumerate(lines[1:], 1):
    parts = re.split(r"\s+", ln.strip(), maxsplit=len(raw_headers) - 1)
    while len(parts) < len(raw_headers):
        parts.append("-")
    uid = parts[col_idx["UID"]] if "UID" in col_idx else "-"
    pid = parts[col_idx["PID"]] if "PID" in col_idx else "-"
    ppid = parts[col_idx["PPID"]] if "PPID" in col_idx else "-"
    stime = parts[col_idx["STIME"]] if "STIME" in col_idx else "-"
    ctime = parts[col_idx["TIME"]] if "TIME" in col_idx else "-"
    cmd = parts[col_idx["CMD"]] if "CMD" in col_idx else parts[-1]
    rows.append([str(i), pid, ppid, uid, stime, ctime, cmd])

headers = ["#", "PID", "PPID", "USER", "STIME", "TIME", "COMMAND"]
widths = [max(len(x) for x in col) for col in zip(headers, *rows)]
term_cols = shutil.get_terminal_size((180, 20)).columns
overhead = 1 + 3 * len(headers)
max_total = max(65, term_cols - 1)
if sum(widths) + overhead > max_total:
    avail = max(20, widths[-1] - ((sum(widths) + overhead) - max_total))
    widths[-1] = avail
    for r in rows:
        if len(r[-1]) > avail:
            r[-1] = r[-1][:max(1, avail - 1)] + "…"

line_fn = lambda l, m, r: l + m.join("─" * (w + 2) for w in widths) + r
def fmt_row(cols, col_code=""):
    cells = []
    for idx, val in enumerate(cols):
        pad = val.ljust(widths[idx])
        cells.append(f"{col_code}{pad}\033[0m" if col_code else pad)
    return "│ " + " │ ".join(cells) + " │"

print(f"=== TOP: {cname} ({len(rows)} processes) ===")
print(line_fn("┌", "┬", "┐"))
print(fmt_row(headers))
print(line_fn("├", "┼", "┤"))
pids_set = {r[1] for r in rows}
for idx, r in enumerate(rows):
    is_root_proc = (idx == 0) or (r[2] not in pids_set)
    c_code = "\033[36m" if is_root_proc else ""
    print(fmt_row(r, c_code))
print(line_fn("└", "┴", "┘"))
PY
      exit $?
      ;;
    -x|--exec)
      shift
      TARGET_ARG="${1:-}"
      [[ -z "$TARGET_ARG" ]] && { echo "Dùng: dps -x <tên_hoặc_#_hoặc_đường_dẫn> [service] [shell]" >&2; exit 1; }
      if CFILE="$(resolve_compose_context "$TARGET_ARG")"; then
        shift
        SVC_ARG=""
        SHELL_ARG=""
        if [[ -n "${1:-}" ]]; then
          if [[ "$1" == /* ]]; then
            SHELL_ARG="$1"
          else
            SVC_ARG="$1"
            SHELL_ARG="${2:-}"
          fi
        fi
        mapfile -t PROJ_CTRS < <(get_project_containers "$CFILE" "1" "$SVC_ARG")
        if [[ ${#PROJ_CTRS[@]} -eq 0 ]]; then
          echo "Không có container đang chạy trong dự án: $CFILE" >&2
          exit 1
        elif [[ ${#PROJ_CTRS[@]} -gt 1 ]]; then
          echo "Dự án có nhiều container đang chạy, hãy chỉ định thêm tên service:" >&2
          printf "  - %s\n" "${PROJ_CTRS[@]}" >&2
          exit 1
        fi
        TARGET_C="${PROJ_CTRS[0]}"
        if [[ -n "$SHELL_ARG" ]]; then
          exec docker exec -it "$TARGET_C" "$SHELL_ARG"
        fi
        docker exec -it "$TARGET_C" /bin/bash 2>/dev/null || exec docker exec -it "$TARGET_C" /bin/sh
        exit $?
      fi
      shift
      c="${1:-}"
      [[ -z "$c" ]] && { echo "Dùng: dps -x <tên_hoặc_id_container> [shell]" >&2; exit 1; }
      sh_bin="${2:-/bin/bash}"
      if [[ -z "${2:-}" ]] && ! docker exec "$c" test -x /bin/bash 2>/dev/null; then
        sh_bin="/bin/sh"
      fi
      exec docker exec -it "$c" "$sh_bin"
      ;;
    -w|--watch)
      shift
      if [[ -n "${1:-}" ]] && CFILE="$(resolve_compose_context "$1")"; then
        mapfile -t PROJ_CTRS < <(get_project_containers "$CFILE" "1" "${2:-}")
        [[ ${#PROJ_CTRS[@]} -eq 0 ]] && { echo "Không có container đang chạy trong dự án: $CFILE" >&2; exit 1; }
        exec docker stats "${PROJ_CTRS[@]}"
      fi
      shift
      exec docker stats "$@"
      ;;
    -c|--config|--inspect)
      INSPECT_MODE=1
      if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
        shift
        TARGET="$1"
      fi
      ;;
    -l|--logs)
      shift
      TARGET_ARG="${1:-}"
      [[ -z "$TARGET_ARG" ]] && { echo "Dùng: dps -l <tên_hoặc_#_hoặc_đường_dẫn> [service] [N]" >&2; exit 1; }
      if CFILE="$(resolve_compose_context "$TARGET_ARG")"; then
        shift
        SVC_ARG=""
        LINES_N="20"
        if [[ -n "${1:-}" ]]; then
          if [[ "$1" =~ ^[0-9]+$ ]]; then
            LINES_N="$1"
          else
            SVC_ARG="$1"
            [[ "${2:-}" =~ ^[0-9]+$ ]] && LINES_N="$2"
          fi
        fi
        mapfile -t PROJ_CTRS < <(get_project_containers "$CFILE" "0" "$SVC_ARG")
        if [[ ${#PROJ_CTRS[@]} -eq 0 ]]; then
          echo "Không tìm thấy container trong dự án: $CFILE" >&2
          exit 1
        elif [[ ${#PROJ_CTRS[@]} -gt 1 ]]; then
          echo "Dự án có nhiều container, hãy chỉ định thêm tên service:" >&2
          printf "  - %s\n" "${PROJ_CTRS[@]}" >&2
          exit 1
        fi
        exec docker logs  --tail "$LINES_N" "${PROJ_CTRS[0]}"
      fi
      LOG_MODE=1
      if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
        shift
        TARGET="$1"
      fi
      if [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]]; then
        shift
        TAIL="$1"
      fi
      ;;
    -f|--follow)
      shift
      TARGET_ARG="${1:-}"
      [[ -z "$TARGET_ARG" ]] && { echo "Dùng: dps -f <tên_hoặc_#_hoặc_đường_dẫn> [service] [N]" >&2; exit 1; }
      if CFILE="$(resolve_compose_context "$TARGET_ARG")"; then
        shift
        SVC_ARG=""
        LINES_N="20"
        if [[ -n "${1:-}" ]]; then
          if [[ "$1" =~ ^[0-9]+$ ]]; then
            LINES_N="$1"
          else
            SVC_ARG="$1"
            [[ "${2:-}" =~ ^[0-9]+$ ]] && LINES_N="$2"
          fi
        fi
        mapfile -t PROJ_CTRS < <(get_project_containers "$CFILE" "0" "$SVC_ARG")
        if [[ ${#PROJ_CTRS[@]} -eq 0 ]]; then
          echo "Không tìm thấy container trong dự án: $CFILE" >&2
          exit 1
        elif [[ ${#PROJ_CTRS[@]} -gt 1 ]]; then
          echo "Dự án có nhiều container, hãy chỉ định thêm tên service:" >&2
          printf "  - %s\n" "${PROJ_CTRS[@]}" >&2
          exit 1
        fi
        exec docker logs -f --tail "$LINES_N" "${PROJ_CTRS[0]}"
      fi
      FOLLOW_MODE=1
      if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
        shift
        TARGET="$1"
      fi
      if [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]]; then
        shift
        TAIL="$1"
      fi
      ;;
    -*)
      echo "Tùy chọn không hỗ trợ: $1 (xem dps -h)" >&2
      exit 1
      ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$1"
      elif [[ "$1" =~ ^[0-9]+$ ]]; then
        TAIL="$1"
      fi
      ;;
  esac
  shift || true
done

if [[ "$HELP_MODE" == "1" ]]; then
  cat <<'HELP_EOF'
[1mdps[0m — Trình quản lý & giám sát nhanh Docker CLI (Debian 12)
[90mHỗ trợ gọi từ bất kỳ thư mục nào qua tên container, số thứ tự #, tên dự án ~/docker/ hoặc đường dẫn Compose.[0m

[1;33mCÚ PHÁP:[0m
  [36mdps[0m [tùy_chọn] [mục_tiêu] [service / tham_số]

[1;33m1. TRẠNG THÁI & CẤU HÌNH:[0m
  [32mdps[0m [mục_tiêu]                   Xem container đang chạy & restarting (CONTAINER, STATUS, PORTS, NETWORKS)
  [32mdps -a[0m [mục_tiêu]                Xem toàn bộ container kể cả đã dừng (thêm STATE, HEALTH, RESTART, DISK)
  [32mdps -c[0m <mục_tiêu> [service]      Xem chi tiết cấu hình, image, lệnh chạy, network, mount & file compose
  [32mdps -h[0m | [32m--help[0m                  Hiển thị bảng hướng dẫn sử dụng này

[1;33m2. ĐIỀU KHIỂN VÒNG ĐỜI & TƯƠNG TÁC:[0m
  [32mdps -u[0m [mục_tiêu] [service...]   Chạy docker compose up -d (tại thư mục hiện tại hoặc từ đường dẫn dự án)
  [32mdps -r[0m <mục_tiêu> [service]      Khởi động lại (docker restart) 1 container hoặc toàn bộ dự án
  [32mdps -k[0m <mục_tiêu> [service]      Dừng (docker stop) 1 container đang chạy hoặc toàn bộ dự án
  [32mdps -m[0m <mục_tiêu> [service]      Dừng và xóa hẳn (docker rm -f) container hoặc toàn bộ dự án
  [32mdps -x[0m <mục_tiêu> [service] [sh] Mở shell tương tác docker exec -it (tự ưu tiên /bin/bash -> /bin/sh)

[1;33m3. GIÁM SÁT TÀI NGUYÊN, TIẾN TRÌNH & SỰ KIỆN:[0m
  [32mdps -s[0m [-a] [mục_tiêu]           Xem mức tiêu thụ CPU, MEM, RESTART, DISK (-a để tính cả container dừng)
  [32mdps -w[0m [mục_tiêu] [service]      Mở màn hình theo dõi tài nguyên thời gian thực (docker stats)
  [32mdps -t[0m <mục_tiêu> [service]      Xem bảng tiến trình đang chạy trong container (docker top)
  [32mdps -e[0m [từ_khóa]                 Theo dõi luồng sự kiện Docker real-time (docker events, Ctrl+C để thoát)

[1;33m4. MẠNG, LƯU TRỮ & IMAGE:[0m
  [32mdps -n[0m [tên_mạng]                Xem danh sách Docker networks, driver, subnet, gateway & container kết nối
  [32mdps -p[0m [mục_tiêu]                Xem chi tiết kết nối mạng (HOST/EXPOSE PORTS, NETWORKS, IP, PEER)
  [32mdps -d[0m [-a] [mục_tiêu]           Xem dung lượng DISK, VIRTUAL, đường dẫn file compose & chi tiết MOUNTS
  [32mdps -i[0m [từ_khóa]                 Xem danh sách Docker images kèm trạng thái STATE và USED BY
  [32mdps -o[0m                           Thống kê tổng quan dung lượng Docker, volume mồ côi & writable layer

[1;33m5. NHẬT KÝ HOẠT ĐỘNG (LOGS):[0m
  [32mdps -l[0m <mục_tiêu> [service] [N]  Xem N dòng log cuối (mặc định 20 dòng)
  [32mdps -f[0m <mục_tiêu> [service] [N]  Xem N dòng log cuối (mặc định 20) và theo dõi trực tiếp (Ctrl+C để thoát)

[1;33mQUY ƯỚC <mục_tiêu> & VÍ DỤ:[0m
  [90m• Tên / Số thứ tự # :[0m dps -r mosquitto   |  dps -l 1 50
  [90m• Dự án ~/docker/   :[0m dps -u dozzle      |  dps -r homeassistant mosquitto
  [90m• Đường dẫn bất kỳ  :[0m dps ~/docker/homeassistant/  |  dps -k ~/docker/homeassistant/
  [90m• Phím tắt Terminal :[0m Nhấn [36mTab[0m để tự động gợi ý tên container, dự án, đường dẫn & service.
HELP_EOF
  exit 0
fi

if [[ "$EVENTS_MODE" == "1" ]]; then
  FILTER="$TARGET" python3 - <<'PY'
import datetime, json, os, subprocess

flt = os.environ.get("FILTER", "").strip().lower()
header = f"=== DOCKER EVENTS (Ctrl+C để thoát){f' | filter: {flt}' if flt else ''} ==="
print(header)

proc = subprocess.Popen(
    ["docker", "events", "--format", "{{json .}}"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True,
    bufsize=1,
)

try:
    assert proc.stdout is not None
    for raw in proc.stdout:
        line = raw.strip()
        if not line:
            continue
        try:
            ev = json.loads(line)
        except Exception:
            if not flt or flt in line.lower():
                print(line, flush=True)
            continue

        ts_nano = ev.get("timeNano") or 0
        ts_sec = ev.get("time") or 0
        if ts_nano:
            dt = datetime.datetime.fromtimestamp(ts_nano / 1e9)
        elif ts_sec:
            dt = datetime.datetime.fromtimestamp(ts_sec)
        else:
            dt = datetime.datetime.now()
        ts_str = dt.strftime("%Y-%m-%d %H:%M:%S")

        etype = (ev.get("Type") or "-").strip()
        action = (ev.get("Action") or "-").strip()
        actor = ev.get("Actor") or {}
        attrs = actor.get("Attributes") or {}
        name = (attrs.get("name") or actor.get("ID") or "-")[:24]

        act_low = action.lower()
        if any(k in act_low for k in ("die", "kill", "oom", "error", "destroy", "unhealthy")):
            badge, color = "[ERR]", "\033[31m"
        elif any(k in act_low for k in ("stop", "pause", "disconnect", "detach")):
            badge, color = "[WRN]", "\033[33m"
        elif any(k in act_low for k in ("start", "create", "healthy", "connect", "pull")):
            badge, color = "[INF]", "\033[36m"
        else:
            badge, color = "[EVT]", ""

        extra = ""
        if "exitCode" in attrs and act_low == "die":
            extra = f" (exitCode={attrs['exitCode']})"

        out = f"{ts_str} {badge} [{etype}] {name} -> {action}{extra}"
        if not flt or flt in out.lower():
            if color:
                print(f"{color}{out}\033[0m", flush=True)
            else:
                print(out, flush=True)
except KeyboardInterrupt:
    proc.terminate()
    try:
        proc.wait(timeout=2)
    except subprocess.TimeoutExpired:
        proc.kill()
    print()
PY
  exit 0
fi

if [[ "$NET_MODE" == "1" ]]; then
  FILTER="$TARGET" python3 - <<'PY'
import json, os, shutil, subprocess

flt = os.environ.get("FILTER", "").strip().lower()
raw_ids = subprocess.check_output(["docker", "network", "ls", "-q"], text=True).splitlines()
n_ids = [x.strip() for x in raw_ids if x.strip()]
if not n_ids:
    raise SystemExit("Không có Docker network nào.")

insp = json.loads(subprocess.check_output(["docker", "network", "inspect", *n_ids], text=True))
rows = []
for net in insp:
    name = (net.get("Name") or "-").strip()
    driver = (net.get("Driver") or "-").strip()
    scope = (net.get("Scope") or "-").strip()
    ipam_cfg = ((net.get("IPAM") or {}).get("Config") or [])
    subnets, gateways = [], []
    for cfg in ipam_cfg:
        if cfg.get("Subnet"): subnets.append(cfg["Subnet"])
        if cfg.get("Gateway"): gateways.append(cfg["Gateway"])
    sub_s = ", ".join(subnets) if subnets else "-"
    gw_s = ", ".join(gateways) if gateways else "-"
    conts = net.get("Containers") or {}
    c_items = []
    for _, cinfo in sorted(conts.items(), key=lambda kv: (kv[1].get("Name") or "").lower()):
        cname = (cinfo.get("Name") or "-").strip()
        cip = ((cinfo.get("IPv4Address") or "").split("/")[0]).strip()
        c_items.append(f"{cname} ({cip})" if cip else cname)
    cont_s = ", ".join(c_items) if c_items else "-"
    prio = 0 if name == "wifi-net" else (1 if name == "ci-local_default" else (2 if name not in ("bridge", "host", "none") else 3))
    search_blob = f"{name} {driver} {scope} {sub_s} {gw_s} {cont_s}".lower()
    if not flt or flt in search_blob:
        rows.append((prio, name, driver, sub_s, gw_s, cont_s, len(c_items) > 0))

rows.sort(key=lambda r: (r[0], r[1].lower()))
headers = ["#", "NETWORK", "DRIVER", "SUBNET", "GATEWAY", "CONTAINERS"]
table = [[str(i), r[1], r[2], r[3], r[4], r[5]] for i, r in enumerate(rows, 1)]

if not table:
    print("Không có network nào khớp.")
    raise SystemExit(0)

widths = [max(len(x) for x in col) for col in zip(headers, *table)]
term_cols = shutil.get_terminal_size((180, 20)).columns
overhead = 1 + 3 * len(headers)
max_total = max(60, term_cols - 1)
if sum(widths) + overhead > max_total:
    avail = max(16, widths[-1] - ((sum(widths) + overhead) - max_total))
    widths[-1] = avail
    for row in table:
        if len(row[-1]) > avail:
            row[-1] = row[-1][:max(1, avail - 1)] + "…"

line_fn = lambda l, m, r: l + m.join("─" * (w + 2) for w in widths) + r
def fmt_row(cols, col_code=""):
    cells = []
    for idx, val in enumerate(cols):
        pad = val.ljust(widths[idx])
        cells.append(f"{col_code}{pad}\033[0m" if col_code else pad)
    return "│ " + " │ ".join(cells) + " │"

print(line_fn("┌", "┬", "┐"))
print(fmt_row(headers))
print(line_fn("├", "┼", "┤"))
for r, raw_r in zip(table, rows):
    c_code = "\033[36m" if raw_r[6] else ""
    print(fmt_row(r, c_code))
print(line_fn("└", "┴", "┘"))
PY
  exit 0
fi

if [[ "$OVERVIEW_MODE" == "1" ]]; then
  python3 - <<'PY'
import json, re, shutil, subprocess

def parse_bytes(s: str) -> float:
    s = (s or "").strip().split("(")[0].strip()
    m = re.match(r"^([0-9.]+)\s*([A-Za-z]+)$", s)
    if not m: return 0.0
    val, unit = float(m.group(1)), m.group(2).lower()
    mult = {"b": 1.0, "kb": 1000.0, "kib": 1024.0, "mb": 1000**2, "mib": 1024**2, "gb": 1000**3, "gib": 1024**3, "tb": 1000**4, "tib": 1024**4}
    return val * mult.get(unit, 1.0)

def fmt_bytes(b: float) -> str:
    if b <= 0: return "0B"
    for u, step in [("GB", 1000**3), ("MB", 1000**2), ("kB", 1000.0)]:
        if b >= step: return f"{b / step:.2f}{u}"
    return f"{int(b)}B"

raw = subprocess.check_output(["docker", "system", "df", "-v"], text=True, stderr=subprocess.DEVNULL)
sec = None
imgs, conts, vols, caches = [], [], [], []
cache_total_str = ""
for line in raw.splitlines():
    st = line.strip()
    if st.startswith("Images space usage:"): sec = "img"; continue
    if st.startswith("Containers space usage:"): sec = "cont"; continue
    if st.startswith("Local Volumes space usage:"): sec = "vol"; continue
    if st.startswith("Build cache usage:"):
        sec = "cache"
        m_c = re.search(r"Build cache usage:\s*(.+)$", st)
        if m_c: cache_total_str = m_c.group(1).strip()
        continue
    if not st or re.match(r"^(REPOSITORY|CONTAINER ID|VOLUME NAME|CACHE ID)\b", st): continue
    cols = re.split(r"\s{2,}", st)
    if sec == "img" and len(cols) >= 8:
        imgs.append({"repo": cols[0], "tag": cols[1], "id": cols[2], "size": cols[4], "shared": cols[5], "unique": cols[6], "cnt": int(re.findall(r"\d+", cols[7])[0]) if re.findall(r"\d+", cols[7]) else 0})
    elif sec == "cont" and len(cols) >= 8:
        conts.append({"id": cols[0], "img": cols[1], "size": cols[4], "status": cols[6], "name": cols[7]})
    elif sec == "vol" and len(cols) >= 3:
        links_m = re.findall(r"\d+", cols[1])
        vols.append({"name": cols[0], "links": int(links_m[0]) if links_m else 0, "size": cols[2]})
    elif sec == "cache" and len(cols) >= 7:
        caches.append({"id": cols[0], "type": cols[1], "size": cols[2], "usage": cols[5], "shared": cols[6]})

img_total = sum(parse_bytes(x["size"]) for x in imgs)
img_active = sum(1 for x in imgs if x["cnt"] > 0)
img_reclaim = sum(parse_bytes(x["unique"]) for x in imgs if x["cnt"] == 0)
cont_total = sum(parse_bytes(x["size"]) for x in conts)
cont_active = sum(1 for x in conts if x["status"].lower().startswith("up"))
cont_reclaim = sum(parse_bytes(x["size"]) for x in conts if not x["status"].lower().startswith("up"))
vol_total = sum(parse_bytes(x["size"]) for x in vols)
vol_active = sum(1 for x in vols if x["links"] > 0)
vol_reclaim = sum(parse_bytes(x["size"]) for x in vols if x["links"] == 0)
cache_total = parse_bytes(cache_total_str) if cache_total_str else sum(parse_bytes(x["size"]) for x in caches)
cache_active = sum(1 for x in caches if str(x["usage"]).strip() not in ("0", ""))
cache_reclaim = sum(parse_bytes(x["size"]) for x in caches if str(x["usage"]).strip() == "0")

summary_rows = [
  ["Images", f"{len(imgs)} ({img_active} used)", str(img_active), fmt_bytes(img_total), fmt_bytes(img_reclaim)],
  ["Containers", f"{len(conts)} ({cont_active} up)", str(cont_active), fmt_bytes(cont_total), fmt_bytes(cont_reclaim)],
  ["Local Volumes", f"{len(vols)} ({len(vols)-vol_active} orphan)", str(vol_active), fmt_bytes(vol_total), fmt_bytes(vol_reclaim)],
  ["Build Cache", str(len(caches)), str(cache_active), fmt_bytes(cache_total), fmt_bytes(cache_reclaim)],
]
headers = ["TYPE", "TOTAL", "ACTIVE", "SIZE", "RECLAIMABLE"]
widths = [max(len(x) for x in col) for col in zip(headers, *summary_rows)]
line_fn = lambda l, m, r: l + m.join("─" * (w + 2) for w in widths) + r
fmt_row = lambda cols: "│ " + " │ ".join(val.ljust(widths[i]) for i, val in enumerate(cols)) + " │"
print(line_fn("┌", "┬", "┐"))
print(fmt_row(headers))
print(line_fn("├", "┼", "┤"))
for r in summary_rows: print(fmt_row(r))
print(line_fn("└", "┴", "┘"))

def render_mini_table(title, t_headers, t_rows, row_colors=None):
    if not t_rows:
        return
    print(f"\n{title}")
    w_cols = [max(len(x) for x in col) for col in zip(t_headers, *t_rows)]
    term_w = shutil.get_terminal_size((180, 20)).columns
    ovh = 1 + 3 * len(t_headers)
    max_w = max(60, term_w - 1)
    if sum(w_cols) + ovh > max_w and len(w_cols) >= 2:
        avail = max(18, w_cols[1] - ((sum(w_cols) + ovh) - max_w))
        w_cols[1] = avail
        for r in t_rows:
            if len(r[1]) > avail:
                r[1] = r[1][:max(1, avail - 1)] + "…"
    mk_line = lambda l, m, r: l + m.join("─" * (w + 2) for w in w_cols) + r
    def mk_row(cols, c_code=""):
        cells = []
        for idx, val in enumerate(cols):
            pad = val.ljust(w_cols[idx])
            cells.append(f"{c_code}{pad}\033[0m" if c_code else pad)
        return "│ " + " │ ".join(cells) + " │"
    print(mk_line("┌", "┬", "┐"))
    print(mk_row(t_headers))
    print(mk_line("├", "┼", "┤"))
    for idx, r in enumerate(t_rows):
        cc = row_colors[idx] if (row_colors and idx < len(row_colors)) else ""
        print(mk_row(r, cc))
    print(mk_line("└", "┴", "┘"))

orphan_vols = sorted([v for v in vols if v["links"] == 0], key=lambda x: -parse_bytes(x["size"]))
if orphan_vols:
    anon_cnt = sum(1 for v in orphan_vols if re.fullmatch(r"[0-9a-f]{64}", v["name"]))
    named_cnt = len(orphan_vols) - anon_cnt
    v_rows, v_colors = [], []
    for i, v in enumerate(orphan_vols, 1):
        vname = v["name"]
        is_anon = bool(re.fullmatch(r"[0-9a-f]{64}", vname))
        disp_name = f"{vname[:12]}…{vname[-6:]}" if is_anon else vname
        vtype = "anon (hash)" if is_anon else "named"
        sz_b = parse_bytes(v["size"])
        v_rows.append([str(i), disp_name, vtype, v["size"]])
        v_colors.append("\033[33m" if sz_b >= 50 * 1000**2 else "")
    v_title = f"Orphan Volumes (LINKS=0): {len(orphan_vols)} ({named_cnt} named, {anon_cnt} anon) | Reclaimable: {fmt_bytes(vol_reclaim)}"
    render_mini_table(v_title, ["#", "VOLUME NAME", "TYPE", "SIZE"], v_rows, v_colors)

big_conts = sorted([c for c in conts if parse_bytes(c["size"]) > 0], key=lambda x: -parse_bytes(x["size"]))
if big_conts:
    c_rows, c_colors = [], []
    for i, c in enumerate(big_conts, 1):
        st_str = c["status"]
        st_low = st_str.lower()
        if st_low.startswith("up"):
            state_lbl, cc = "running", "\033[36m"
        elif re.search(r"exited \([1-9][0-9]*\)", st_low):
            state_lbl, cc = "error", "\033[31m"
        else:
            state_lbl, cc = "stopped", "\033[90m"
        c_rows.append([str(i), c["name"], c["size"], state_lbl, st_str])
        c_colors.append(cc)
    render_mini_table(f"Container Writable Layer (>0B): {len(big_conts)} containers", ["#", "CONTAINER", "WRITABLE", "STATE", "STATUS"], c_rows, c_colors)
PY
  exit 0
fi

if [[ "$INSPECT_MODE" == "1" ]]; then
  TARGET="$TARGET" python3 - <<'PY'
import json, os, subprocess
target = os.environ.get("TARGET", "").strip()
raw = subprocess.check_output(["docker", "ps", "-a", "--format", "{{.Names}}"], text=True)
names = sorted([x.strip() for x in raw.splitlines() if x.strip()], key=str.lower)
if not names: raise SystemExit("Không có container nào.")
if not target:
    print("Chọn container (dps -c <#> hoặc dps -c <tên>):")
    for i, n in enumerate(names, 1): print(f"  {i}. {n}")
    raise SystemExit(0)
if target.isdigit():
    idx = int(target)
    if idx < 1 or idx > len(names): raise SystemExit(f"Số thứ tự #{idx} nằm ngoài phạm vi 1..{len(names)}.")
    cname = names[idx - 1]
else:
    matches = [n for n in names if target.lower() in n.lower()]
    if not matches: raise SystemExit(f"Không tìm thấy container khớp: {target}")
    cname = matches[0]
obj = json.loads(subprocess.check_output(["docker", "inspect", cname], text=True))[0]
home = os.path.expanduser("~")
def sp(p):
    p = (p or "").strip()
    return ("~" + p[len(home):]) if (home and p.startswith(home)) else (p or "-")
cfg = obj.get("Config") or {}
hc = obj.get("HostConfig") or {}
st = obj.get("State") or {}
labels = cfg.get("Labels") or {}
nets = (obj.get("NetworkSettings") or {}).get("Networks") or {}
ep = cfg.get("Entrypoint") or []
cmd = cfg.get("Cmd") or []
ep_s = " ".join(ep) if isinstance(ep, list) else str(ep or "-")
cmd_s = " ".join(cmd) if isinstance(cmd, list) else str(cmd or "-")
rp = ((hc.get("RestartPolicy") or {}).get("Name") or "no")
proj = labels.get("com.docker.compose.project") or "-"
cfile = ", ".join(sp(x) for x in (labels.get("com.docker.compose.project.config_files") or "").split(",") if x.strip()) or "-"
print(f"=== CONFIG: {cname} ===")
print(f"Image      : {cfg.get('Image') or '-'}")
print(f"Status     : {st.get('Status') or '-'}")
print(f"Restart    : {rp}")
print(f"Entrypoint : {ep_s or '-'}")
print(f"Command    : {cmd_s or '-'}")
print(f"Compose    : {proj} ({cfile})")
print("Networks   :")
if nets:
    for n_k, n_v in sorted(nets.items(), key=lambda kv: (0 if kv[0] == "wifi-net" else (1 if kv[0] == "ci-local_default" else 2), kv[0].lower())):
        ip = ((n_v or {}).get("IPAddress") or "").strip() or "-"
        gw = ((n_v or {}).get("Gateway") or "").strip() or "-"
        print(f"  - {n_k}: IP={ip} | GW={gw}")
else:
    print("  - -")
mounts = obj.get("Mounts") or []
print("Mounts     :")
if mounts:
    for m in mounts:
        m_type = m.get("Type") or "mount"
        src = sp(m.get("Source") or "-")
        dst = m.get("Destination") or "-"
        rw = "rw" if m.get("RW", True) else "ro"
        print(f"  - [{m_type}/{rw}] {src} -> {dst}")
else:
    print("  - -")
PY
  exit 0
fi

if [[ "$LOG_MODE" == "1" || "$FOLLOW_MODE" == "1" ]]; then
  TARGET="$TARGET" TAIL="$TAIL" FOLLOW="$FOLLOW_MODE" python3 - <<'PY'
import os, re, subprocess

target = os.environ.get("TARGET", "").strip()
tail = os.environ.get("TAIL", "20")
follow = os.environ.get("FOLLOW") == "1"
raw = subprocess.check_output(["docker", "ps", "-a", "--format", "{{.Names}}"], text=True)
names = sorted([x.strip() for x in raw.splitlines() if x.strip()], key=str.lower)
if not names: raise SystemExit("Không có container nào.")
if not target: raise SystemExit("Vui lòng nhập tên hoặc số thứ tự # (ví dụ: dps -f 1 hoặc dps -f dozzle 50).")
if target.isdigit():
    idx = int(target)
    if idx < 1 or idx > len(names): raise SystemExit(f"Số thứ tự #{idx} nằm ngoài phạm vi 1..{len(names)}.")
    cname = names[idx - 1]
else:
    matches = [n for n in names if target.lower() in n.lower()]
    if not matches: raise SystemExit(f"Không tìm thấy container khớp: {target}")
    cname = matches[0]

def fmt_log_line(line: str) -> str:
    m = re.match(r"^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})\s+(.*)$", line)
    if m:
        ts, msg = m.group(1).replace("T", " "), m.group(2)
        low = msg.lower()
        badge = "[ERR]" if any(k in low for k in ("error", "err", "fatal", "panic")) else ("[WRN]" if any(k in low for k in ("warn", "wrn")) else "[INF]")
        return f"{ts} {badge} {msg}"
    return line

if follow:
    print(f"=== FOLLOW LOGS: {cname} (last {tail} lines — Ctrl+C để thoát) ===")
    proc = subprocess.Popen(["docker", "logs", "--tail", tail, "--follow", "--timestamps", cname], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
    try:
        assert proc.stdout is not None
        for line in proc.stdout:
            print(fmt_log_line(line.rstrip("\r\n")), flush=True)
    except KeyboardInterrupt:
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()
        print()
else:
    print(f"=== LOGS: {cname} (last {tail} lines) ===")
    logs = subprocess.check_output(["docker", "logs", "--tail", tail, "--timestamps", cname], text=True, stderr=subprocess.STDOUT)
    for line in logs.splitlines():
        print(fmt_log_line(line))
PY
  exit 0
fi

run_render() {
  SHOW_STATS="$SHOW_STATS" FULL_PORTS="$FULL_PORTS" DEPLOY_MODE="$DEPLOY_MODE" IMAGE_MODE="$IMAGE_MODE" WATCH_MODE="$WATCH_MODE" SORT_MODE="$SORT_MODE" ONLY_RUNNING="$ONLY_RUNNING" FILTER="$TARGET" python3 - <<'PY'
import json, os, re, shutil, subprocess

show_stats = os.environ.get("SHOW_STATS") == "1"
full_ports = os.environ.get("FULL_PORTS") == "1"
deploy_mode = os.environ.get("DEPLOY_MODE") == "1"
virtual_map = {}
if deploy_mode:
    try:
        s_out = subprocess.check_output(["docker", "ps", "-a", "-s", "--format", "{{.Names}}	{{.Size}}"], text=True, stderr=subprocess.DEVNULL)
        for line in s_out.splitlines():
            if "	" in line:
                cname_s, sz_s = line.split("	", 1)
                m_v = re.search(r"\(virtual ([^)]+)\)", sz_s)
                if m_v:
                    virtual_map[cname_s.strip()] = m_v.group(1).strip()
    except Exception:
        pass

image_mode = os.environ.get("IMAGE_MODE") == "1"
watch_mode = os.environ.get("WATCH_MODE") == "1"
sort_mode = os.environ.get("SORT_MODE", "").strip().lower()
only_running = (os.environ.get("ONLY_RUNNING") == "1") or watch_mode
flt = os.environ.get("FILTER", "").strip().lower()

if image_mode:
    ps_raw = subprocess.check_output(["docker", "ps", "-a", "--format", "{{.ID}}\t{{.Names}}\t{{.State}}"], text=True)
    c_ids = [l.split("\t")[0].strip() for l in ps_raw.splitlines() if l.strip()]
    used_by_iid, used_by_name = {}, {}
    if c_ids:
        insp = subprocess.check_output(["docker", "inspect", *c_ids], text=True, stderr=subprocess.DEVNULL)
        for obj in json.loads(insp):
            iid_full = (obj.get("Image") or "").replace("sha256:", "").strip()
            iid_short = iid_full[:12]
            cname = ((obj.get("Name") or "").lstrip("/")).strip()
            st = (((obj.get("State") or {}).get("Status")) or "").strip().lower() or "used"
            img_cfg = ((obj.get("Config") or {}).get("Image") or "").strip()
            entry = (st, cname or "-")
            if iid_short:
                used_by_iid.setdefault(iid_short, [])
                if entry not in used_by_iid[iid_short]: used_by_iid[iid_short].append(entry)
            if img_cfg:
                used_by_name.setdefault(img_cfg, [])
                if entry not in used_by_name[img_cfg]: used_by_name[img_cfg].append(entry)
    raw = subprocess.check_output(["docker", "images", "--format", "{{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}"], text=True)
    rows = []
    for line in raw.splitlines():
        if not line.strip(): continue
        parts = line.split("\t")
        while len(parts) < 5: parts.append("")
        repo, tag, iid, size, created = [p.strip() or "-" for p in parts[:5]]
        iid_s = iid.replace("sha256:", "")[:12]
        ref_full = f"{repo}:{tag}" if tag != "<none>" else repo
        entries = list(used_by_iid.get(iid_s, []))
        for extra in used_by_name.get(ref_full, []):
            if extra not in entries: entries.append(extra)
        entries.sort(key=lambda x: (0 if x[0] == "running" else 1, x[1].lower()))
        states_list = []
        for st_v, _ in entries:
            if st_v not in states_list: states_list.append(st_v)
        mixed = len(states_list) > 1
        cnames_list = []
        for st_v, cn_v in entries:
            lbl = f"{cn_v} ({st_v})" if mixed else cn_v
            if lbl not in cnames_list: cnames_list.append(lbl)
        state_str = ", ".join(states_list) if states_list else "-"
        used_str = ", ".join(cnames_list) if cnames_list else "-"
        is_pure_running = (states_list == ["running"])
        has_running = ("running" in states_list)
        is_used = len(entries) > 0
        prio = 0 if is_pure_running else (1 if has_running else (2 if is_used else 3))
        if not flt or flt in f"{repo} {tag} {iid_s} {size} {created} {state_str} {used_str}".lower():
            rows.append((repo, tag, iid_s, size, created, state_str, used_str, prio, has_running, is_used))
    rows.sort(key=lambda r: (r[7], r[0].lower(), r[1].lower()))
    headers = ["#", "REPOSITORY", "TAG", "IMAGE ID", "SIZE", "CREATED", "STATE", "USED BY"]
    table = [[str(i), r[0], r[1], r[2], r[3], r[4], r[5], r[6]] for i, r in enumerate(rows, 1)]
    if not table:
        print("Không có image nào khớp.")
    else:
        widths = [max(len(x) for x in col) for col in zip(headers, *table)]
        term_cols = shutil.get_terminal_size((180, 20)).columns
        overhead = 1 + 3 * len(headers)
        max_total = max(60, term_cols - 1)
        if sum(widths) + overhead > max_total:
            for idx in [len(headers) - 1, 1]:
                if sum(widths) + overhead > max_total:
                    avail = max(14, widths[idx] - ((sum(widths) + overhead) - max_total))
                    widths[idx] = avail
                    for row in table:
                        if len(row[idx]) > avail:
                            row[idx] = row[idx][:max(1, avail - 1)] + "…"
        line_fn = lambda l, m, r: l + m.join("─" * (w + 2) for w in widths) + r
        def fmt_row(cols, col_code=""):
            cells = []
            for idx, val in enumerate(cols):
                pad = val.ljust(widths[idx])
                cells.append(f"{col_code}{pad}\033[0m" if col_code else pad)
            return "│ " + " │ ".join(cells) + " │"
        print(line_fn("┌", "┬", "┐"))
        print(fmt_row(headers))
        print(line_fn("├", "┼", "┤"))
        for r, raw_r in zip(table, rows):
            c_code = "\033[36m" if raw_r[8] else ("\033[32m" if raw_r[9] else "")
            print(fmt_row(r, c_code))
        print(line_fn("└", "┴", "┘"))
    used_cnt = sum(1 for r in rows if r[9])
    unused_cnt = sum(1 for r in rows if not r[9])
    print(f"Total images: {len(rows)} | In use: {used_cnt} | Unused: {unused_cnt}")
    raise SystemExit(0)

need_size = (not full_ports)
fmt_str = "{{.ID}}\t{{.Names}}\t{{.State}}\t{{.Status}}\t{{.Ports}}\t{{.Networks}}\t{{.Image}}" + ("\t{{.Size}}" if need_size else "")
ps_cmd = ["docker", "ps", "-a"] + (["--size"] if need_size else []) + ["--format", fmt_str]
raw = subprocess.check_output(ps_cmd, text=True)
ids = [l.split("\t")[0].strip() for l in raw.splitlines() if l.strip()]
home = os.path.expanduser("~")
def short_path(p: str) -> str:
    p = (p or "").strip()
    if not p: return "-"
    if home and p.startswith(home): return "~" + p[len(home):]
    return p

net_info_map, compose_map, restart_map, mounts_map, health_map = {}, {}, {}, {}, {}
if ids:
    insp = subprocess.check_output(["docker", "inspect", *ids], text=True, stderr=subprocess.DEVNULL)
    for obj in json.loads(insp):
        cid = (obj.get("Id") or "")[:12]
        st_obj = obj.get("State") or {}
        cfg_obj = obj.get("Config") or {}
        h_obj = st_obj.get("Health") or {}
        if h_obj.get("Status"):
            health_map[cid] = h_obj["Status"].strip().lower()
        elif cfg_obj.get("Healthcheck"):
            health_map[cid] = "configured"
        else:
            health_map[cid] = "-"
        nets = (obj.get("NetworkSettings") or {}).get("Networks") or {}
        ordered = sorted(nets.items(), key=lambda kv: (0 if kv[0] == "wifi-net" else (1 if kv[0] == "ci-local_default" else 2), kv[0].lower()))
        entries = [(n_name, ((n_cfg or {}).get("IPAddress") or "").strip() or "-") for n_name, n_cfg in ordered]
        net_info_map[cid] = entries
        labels = ((obj.get("Config") or {}).get("Labels")) or {}
        cfg_files = (labels.get("com.docker.compose.project.config_files") or "").strip()
        work_dir = (labels.get("com.docker.compose.project.working_dir") or "").strip()
        if cfg_files:
            c_list = [short_path(x) for x in cfg_files.split(",") if x.strip()]
            compose_map[cid] = ", ".join(c_list) if c_list else "-"
        elif work_dir:
            compose_map[cid] = short_path(work_dir)
        else:
            compose_map[cid] = "-"
        rp = (((obj.get("HostConfig") or {}).get("RestartPolicy")) or {}).get("Name") or "no"
        restart_map[cid] = rp.strip() or "no"
        m_list = []
        for m in (obj.get("Mounts") or []):
            src = (m.get("Source") or "").strip()
            if src:
                sp = short_path(src)
                if sp not in m_list: m_list.append(sp)
        mounts_map[cid] = "\n".join(m_list) if m_list else "-"

def parse_mem_mib(mem_s: str) -> float:
    m = re.match(r"^([0-9.]+)\s*([A-Za-z]+)$", (mem_s or "").strip())
    if not m: return -1.0
    val, unit = float(m.group(1)), m.group(2).lower()
    mult = {"b": 1/(1024*1024), "kb": 1/1024, "kib": 1/1024, "mb": 1.0, "mib": 1.0, "gb": 1024.0, "gib": 1024.0}
    return val * mult.get(unit, 1.0)

def parse_cpu_pct(cpu_s: str) -> float:
    m = re.match(r"^([0-9.]+)%$", (cpu_s or "").strip())
    return float(m.group(1)) if m else -1.0

cpu_map, mem_map, metric_map = {}, {}, {}
if (show_stats or watch_mode) and not full_ports and not deploy_mode:
    s_raw = subprocess.check_output(["docker", "stats", "--no-stream", "--format", "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"], text=True, stderr=subprocess.DEVNULL)
    for l in s_raw.splitlines():
        p = l.split("\t")
        if len(p) >= 3:
            cname_s, cpu_s, mem_s = p[0].strip(), p[1].strip(), p[2].split("/")[0].strip()
            cpu_map[cname_s] = cpu_s or "-"
            mem_map[cname_s] = mem_s or "-"
            metric_map[cname_s] = (parse_cpu_pct(cpu_s), parse_mem_mib(mem_s))

def fmt_disk(sz: str) -> str:
    s = (sz or "").strip()
    if not s: return "-"
    return s.split("(")[0].strip() or "-"

def split_ports(p: str, full: bool = False):
    if not p.strip(): return "-", "-"
    seen, mapped, exposed = set(), [], []
    for item in p.split(","):
        it = re.sub(r"^(?:0\.0\.0\.0:|\[::\]:)", "", item.strip())
        if not it: continue
        if not full:
            m = re.match(r"^(\d+)->(\d+)(/\w+)$", it)
            if m and m.group(1) == m.group(2): it = f"{m.group(1)}{m.group(3)}"
        if it in seen: continue
        seen.add(it)
        if "->" in it: mapped.append(it)
        else: exposed.append(it)
    return (", ".join(mapped) if mapped else "-"), (", ".join(exposed) if exposed else "-")

def fmt_ports(p: str, full: bool = False) -> str:
    m_s, e_s = split_ports(p, full)
    parts = [x for x in (m_s, e_s) if x != "-"]
    return " | ".join(parts) if parts else "-"

def fmt_nets(n: str) -> str:
    if not n.strip(): return "-"
    items = [x.strip() for x in n.split(",") if x.strip()]
    items.sort(key=lambda x: (0 if x == "wifi-net" else (1 if x == "ci-local_default" else 2), x.lower()))
    return ", ".join(items) if items else "-"

rows, all_states = [], []
for line in raw.splitlines():
    if not line.strip(): continue
    parts = line.split("\t")
    while len(parts) < 8: parts.append("")
    cid, name, state, status, ports, nets, image, size_raw = [p.strip() for p in parts[:8]]
    cid_short = cid[:12]
    st_low = state.lower()
    all_states.append(st_low)
    if full_ports and st_low != "running": continue
    if only_running and st_low not in ("running", "restarting"): continue
    entries = net_info_map.get(cid_short, [])
    if not entries and nets.strip():
        ns = [x.strip() for x in nets.split(",") if x.strip()]
        ns.sort(key=lambda x: (0 if x == "wifi-net" else (1 if x == "ci-local_default" else 2), x.lower()))
        entries = [(x, "-") for x in ns]
    main_net = entries[0][0] if entries else "-"
    main_ip = entries[0][1] if entries else "-"
    peer_nets = ", ".join(x[0] for x in entries[1:]) if len(entries) > 1 else "-"
    peer_ips = ", ".join(x[1] for x in entries[1:]) if len(entries) > 1 else "-"
    disk_val = fmt_disk(size_raw)
    compose_val = compose_map.get(cid_short, "-")
    restart_val = restart_map.get(cid_short, "no")
    mounts_val = mounts_map.get(cid_short, "-")
    mounts_search = mounts_val.replace("\n", ", ")
    h_ports, e_ports = split_ports(ports, full_ports)
    p_fmt, n_fmt = fmt_ports(ports, full_ports), fmt_nets(nets)
    cpu_val = cpu_map.get(name, "-") if ((show_stats or watch_mode) and not full_ports and not deploy_mode) else "-"
    mem_val = mem_map.get(name, "-") if ((show_stats or watch_mode) and not full_ports and not deploy_mode) else "-"
    cpu_f, mem_f = metric_map.get(name, (-1.0, -1.0))
    if not flt or flt in f"{cid_short} {name} {state} {status} {restart_val} {cpu_val} {mem_val} {disk_val} {mounts_search} {main_net} {main_ip} {peer_nets} {peer_ips} {h_ports} {e_ports} {p_fmt} {n_fmt} {compose_val} {image}".lower():
        rows.append((cid_short, name, state, status, restart_val, cpu_val, mem_val, disk_val, p_fmt, n_fmt, h_ports, e_ports, main_net, main_ip, peer_nets, peer_ips, compose_val, mounts_val, 0 if st_low == "running" else 1, cpu_f, mem_f))

if (show_stats or watch_mode) and not full_ports and not deploy_mode and sort_mode == "mem":
    rows.sort(key=lambda r: (r[18], -r[20], r[1].lower()))
elif (show_stats or watch_mode) and not full_ports and not deploy_mode and sort_mode == "cpu":
    rows.sort(key=lambda r: (r[18], -r[19], r[1].lower()))
else:
    rows.sort(key=lambda r: r[1].lower())

def color_for(state, status):
    st, s = state.lower(), status.lower()
    if "unhealthy" in s or st == "restarting" or re.search(r"exited \([1-9][0-9]*\)", s): return "\033[31m"
    if "healthy" in s: return "\033[32m"
    if st == "running": return "\033[36m"
    if "exited (0)" in s: return ""
    return "\033[35m"

if full_ports:
    headers = ["#", "CONTAINER", "HOST PORTS", "EXPOSE PORTS", "NETWORKS", "IP", "PEER NETWORKS", "PEER IP"]
    table = [[str(i), r[1], r[10], r[11], r[12], r[13], r[14], r[15]] for i, r in enumerate(rows, 1)]
elif deploy_mode:
    headers = ["#", "CONTAINER", "DISK", "VIRTUAL", "COMPOSE FILE", "MOUNTS"]
    table = [[str(i), r[1], r[7], virtual_map.get(r[1], "-"), r[16], r[17]] for i, r in enumerate(rows, 1)]
elif show_stats or watch_mode:
    headers = ["#", "CONTAINER", "STATUS", "RESTART", "CPU", "MEM", "DISK"]
    table = [[str(i), r[1], r[3], r[4], r[5], r[6], r[7]] for i, r in enumerate(rows, 1)]
else:
    def fmt_state_lbl(st_raw, status_raw):
        st_l, s_l = st_raw.lower(), status_raw.lower()
        if "unhealthy" in s_l or re.search(r"exited \([1-9][0-9]*\)", s_l):
            return "error"
        if st_l == "exited":
            return "stopped"
        return st_l or "-"
    if not only_running:
        headers = ["#", "CONTAINER", "STATE", "HEALTH", "STATUS", "RESTART", "DISK", "PORTS", "NETWORKS"]
        table = [[str(i), r[1], fmt_state_lbl(r[2], r[3]), health_map.get(r[0], "-"), r[3], r[4], r[7], r[8], r[9]] for i, r in enumerate(rows, 1)]
    else:
        headers = ["#", "CONTAINER", "STATUS", "PORTS", "NETWORKS"]
        table = [[str(i), r[1], r[3], r[8], r[9]] for i, r in enumerate(rows, 1)]

if not table:
    print("Không có container nào khớp.")
else:
    widths = []
    for c_idx, h in enumerate(headers):
        max_v = len(h)
        for row in table:
            for ln in row[c_idx].split("\n"):
                if len(ln) > max_v: max_v = len(ln)
        widths.append(max_v)
    term_cols = shutil.get_terminal_size((180, 20)).columns
    overhead = 1 + 3 * len(headers)
    max_total = max(60, term_cols - 1)
    if sum(widths) + overhead > max_total:
        flex_order = [len(headers) - 1, len(headers) - 2]
        for idx in flex_order:
            if idx < len(widths) and sum(widths) + overhead > max_total:
                avail = max(12, widths[idx] - ((sum(widths) + overhead) - max_total))
                widths[idx] = avail
                for r_i, row in enumerate(table):
                    new_lines = []
                    for ln in row[idx].split("\n"):
                        new_lines.append(ln[:max(1, avail - 1)] + "…" if len(ln) > avail else ln)
                    table[r_i][idx] = "\n".join(new_lines)
    line_fn = lambda l, m, r: l + m.join("─" * (w + 2) for w in widths) + r
    def render_row_lines(cols, col_code=""):
        split_cols = [c.split("\n") for c in cols]
        max_h = max(len(sc) for sc in split_cols)
        out = []
        for h_i in range(max_h):
            cells = []
            for idx, sc in enumerate(split_cols):
                val = sc[h_i] if h_i < len(sc) else ""
                pad = val.ljust(widths[idx])
                cells.append(f"{col_code}{pad}\033[0m" if col_code else pad)
            out.append("│ " + " │ ".join(cells) + " │")
        return out
    print(line_fn("┌", "┬", "┐"))
    for l_out in render_row_lines(headers): print(l_out)
    print(line_fn("├", "┼", "┤"))
    for r_idx, (r, raw_r) in enumerate(zip(table, rows)):
        for l_out in render_row_lines(r, color_for(raw_r[2], raw_r[3])): print(l_out)
        if deploy_mode and r_idx < len(table) - 1:
            print(line_fn("├", "┼", "┤"))
    print(line_fn("└", "┴", "┘"))

PY
}

if [[ "$WATCH_MODE" == "1" ]]; then
  trap 'printf "\n"' INT
  while true; do
    OUT="$(run_render 2>&1)" || true
    printf "\033[H\033[2J[Watch 2s — Ctrl+C để thoát]\n%s\n" "$OUT"
    sleep 2 || break
  done
else
  run_render
fi
