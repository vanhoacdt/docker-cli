# dps - Docker PS, Image, Log & Disk Overview CLI (Debian 12) — `v0.0.1`

Công cụ dòng lệnh xem nhanh trạng thái container, image, cấu hình, log và dung lượng hệ thống Docker.

## Cài đặt nhanh (từ thư mục repo)

```bash
chmod +x dps.sh
sudo ln -sf "$(pwd)/dps.sh" /usr/local/bin/dps
sudo cp dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

## Cài đặt khi chuyển máy mới

1. Cài `git`, `python3`, `bash-completion` (nếu máy mới chưa có) và clone repository:

```bash
sudo apt-get update && sudo apt-get install -y git python3 bash-completion
git clone https://github.com/vanhoacdt/docker-cli.git ~/dps-cli
cd ~/dps-cli
```

2. Liên kết lệnh `dps` và kích hoạt tab completion:

```bash
chmod +x ~/dps-cli/dps.sh
sudo ln -sf ~/dps-cli/dps.sh /usr/local/bin/dps
sudo cp ~/dps-cli/dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

3. Kiểm tra nhanh sau khi chuyển máy:

```bash
which dps && dps -h
```

## Cách dùng

- `dps [từ_khóa]` — Danh sách container (`CONTAINER`, `STATUS`, `RESTART`, `DISK`, `PORTS`, `NETWORKS`)
- `dps -s [mem|cpu|run|từ_khóa]` — Xem `CPU`, `MEM`, `RESTART`, `DISK`
- `dps -w [mem|cpu|từ_khóa]` — Theo dõi trực tiếp `CPU` & `MEM` container đang chạy (làm mới mỗi 2s)
- `dps -d [từ_khóa]` — Xem `DISK`, `COMPOSE FILE` và `MOUNTS`
- `dps -p [từ_khóa]` — Xem container đang chạy + tách `HOST/EXPOSE PORTS`, `NETWORKS`, `IP`, `PEER`
- `dps -i [từ_khóa]` — Danh sách Docker images kèm cột `STATE` và `USED BY`
- `dps -c <tên_hoặc_#>` — Cấu hình, network, mount và compose của 1 container
- `dps -o` — Tổng quan dung lượng `Images`, `Containers`, `Local Volumes`, `Build Cache` & orphan volumes
- `dps -l <tên_hoặc_#> [N]` — Xem `N` dòng log cuối (mặc định 40)
- `dps -f <tên_hoặc_#> [N]` — Theo dõi `N` dòng log trực tiếp (mặc định 40)
- `dps -h` — Trợ giúp