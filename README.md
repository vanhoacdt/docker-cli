# dps - Docker PS, Image, Log & Disk Overview CLI (Debian 12) — `v0.0.1`

Ngôn ngữ : [Tiếng Việt](./README.md)  | Language : [English](./README.en.md) | 言語 : [日本語](./README.ja.md) | 语言 : [简体中文](./README.zh.md)



Công cụ dòng lệnh xem nhanh trạng thái container, image, cấu hình, log và dung lượng hệ thống Docker.

## Cài đặt nhanh (từ thư mục repo)

```bash
chmod +x dps.sh
sudo ln -sf "$(pwd)/dps.sh" /usr/local/bin/dps
sudo cp dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

## Cài đặt khi chuyển máy mới

1. Cập nhật danh sách gói, cài `git`, cài `python3` và `bash-completion` (nếu máy mới chưa có), sau đó clone repository:

```bash
sudo apt-get update
sudo apt-get install -y git
sudo apt-get install -y python3 bash-completion
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

## Cập nhật thay đổi lên GitHub

1. Chuyển vào thư mục repository và kiểm tra các tệp đã chỉnh sửa:

```bash
cd ~/dps-cli
git status
```

2. Thêm thay đổi, tạo commit và đẩy lên nhánh `main` trên GitHub:

```bash
git add .
git commit -m "chore: update dps cli"
git push origin main
```

3. Nạp lại completion nếu bạn vừa chỉnh sửa tệp completion:

```bash
sudo cp ~/dps-cli/dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

## Gỡ cài đặt khỏi hệ thống

1. Hủy tab completion trong phiên shell hiện tại và chuyển ra ngoài thư mục `~/dps-cli` (nếu đang đứng bên trong):

```bash
complete -r dps 2>/dev/null || true
cd ~
```

2. Xóa symlink lệnh, file completion và thư mục mã nguồn:

```bash
sudo rm -f /usr/local/bin/dps
sudo rm -f /etc/bash_completion.d/dps
rm -rf ~/dps-cli
```

3. Kiểm tra lại sau khi gỡ:

```bash
which dps 2>/dev/null || echo "Đã gỡ dps"
```

## Cách dùng

- `dps [từ_khóa]` — Danh sách container đang chạy (`CONTAINER`, `STATUS`, `PORTS`, `NETWORKS`)
- `dps -a [từ_khóa]` — Danh sách toàn bộ container kể cả đã dừng (format như `dps`)
- `dps -u [service...]` — Chạy `docker compose up -d` ở thư mục hiện tại
- `dps -r <tên_hoặc_#>` — Khởi động lại (`docker restart`) container theo tên hoặc số thứ tự `#`
- `dps -k <tên_hoặc_#>` — Dừng (`docker stop`) container theo tên hoặc số thứ tự `#`
- `dps -m <tên_hoặc_#>` — Dừng và xóa (`docker rm -f`) container theo tên hoặc số thứ tự `#`
- `dps -n [tên_mạng]` — Xem danh sách Docker networks, subnet, gateway & container đang kết nối
- `dps -t <tên_hoặc_#>` — Xem các tiến trình đang chạy trong container (`docker top`)
- `dps -s [-a]` — Xem `CPU`, `MEM`, `RESTART`, `DISK` (thêm `-a` để xem cả container đã dừng)
- `dps -w [tên_container]` — Chạy trực tiếp `docker stats`
- `dps -x <container> [shell]` — Mở shell tương tác `docker exec -it` (`/bin/bash` -> `/bin/sh`)
- `dps -e [từ_khóa]` — Theo dõi sự kiện Docker real-time (`docker events`)
- `dps -d [-a] [từ_khóa]` — Xem `DISK`, `VIRTUAL`, `COMPOSE FILE` và `MOUNTS`
- `dps -p [từ_khóa]` — Xem container đang chạy + tách `HOST/EXPOSE PORTS`, `NETWORKS`, `IP`, `PEER`
- `dps -i [từ_khóa]` — Danh sách Docker images kèm cột `STATE` và `USED BY`
- `dps -c <tên_hoặc_#>` — Cấu hình, network, mount và compose của 1 container
- `dps -o` — Tổng quan dung lượng `Images`, `Containers`, `Local Volumes`, `Build Cache` & orphan volumes
- `dps -l <tên_hoặc_#> [N]` — Xem `N` dòng log cuối (mặc định 20)
- `dps -f <tên_hoặc_#> [N]` — Theo dõi `N` dòng log trực tiếp (mặc định 20)
- `dps -h` — Trợ giúp

## Cơ chế Tab Completion & Nhận diện mục tiêu thông minh

Hệ thống tự động hoàn thành khi bấm phím **`Tab`** hỗ trợ ngữ cảnh linh hoạt cho tất cả các cờ lệnh từ bất kỳ thư mục nào:

- **Gợi ý cờ & container trực tiếp:** Gõ `dps -` rồi bấm `Tab` để liệt kê toàn bộ tùy chọn; gõ `dps ` + `Tab` để gợi ý nhanh tên các container đang chạy và tên dự án trong `~/docker/`.
- **Gợi ý theo ngữ cảnh từng cờ:**
  - `dps -r`, `-k`, `-m`, `-t`, `-x`, `-l`, `-f`, `-w`: Gợi ý các container đang chạy, tên dự án trong `~/docker/` và đường dẫn thư mục/file.
  - `dps -c`, `-a`, `-s`, `-d`, `-p`, `-e`: Gợi ý toàn bộ container (kể cả đã dừng), tên dự án và đường dẫn.
  - `dps -n`: Gợi ý danh sách tên Docker networks hiện có.
  - `dps -i`: Gợi ý danh sách tên repository của Docker images.
- **Hoàn thành đa cấp cho dự án Docker Compose (`-u` và các lệnh khác):**
  1. **Khi đứng ngay trong thư mục chứa `docker-compose.yml`:** Bấm `Tab` sau `dps -u ` sẽ gợi ý danh sách các **service** được khai báo trong file compose đó.
  2. **Khi đứng ở thư mục bất kỳ bên ngoài:** Bấm `Tab` sau `dps -u ` (hoặc `-r`, `-k`, `-l`, `-x`...) sẽ gợi ý tên các **dự án** nằm trong `~/docker/` (ví dụ: `homeassistant`, `dozzle`, `ci-local`...) hoặc hoàn thành đường dẫn thư mục (`~/docker/homeassistant/`).
  3. **Gợi ý tiếp service của dự án:** Sau khi đã nhập xong tên dự án hoặc đường dẫn (ví dụ `dps -u ~/docker/homeassistant/ ` hoặc `dps -r homeassistant `), bấm `Tab` lần nữa sẽ tự động phân tích file compose của dự án đó và gợi ý từng **service** bên trong (kèm các cờ như `--force-recreate`, `--build`, `--no-deps` đối với `-u`).