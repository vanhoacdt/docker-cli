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

### Quy ước tham số phía sau lệnh
* **`[...]` (Ngoặc vuông)**: Tham số **tùy chọn** — có thể bỏ qua.
* **`<...>` (Ngoặc nhọn)**: Tham số **bắt buộc** — phải nhập ít nhất 1 giá trị.
* **`<mục_tiêu>`**: Có thể truyền linh hoạt **1 trong 4 dạng** từ bất kỳ thư mục nào:
  1. **Tên container** (hoặc từ khóa lọc): `mosquitto`, `wifi`
  2. **Số thứ tự `#`** trên bảng `dps`: `1`, `3`
  3. **Tên dự án trong `~/docker/`**: `homeassistant`, `dozzle`
  4. **Đường dẫn thư mục hoặc file `docker-compose.yml`**: `~/docker/homeassistant/`, `./docker-compose.yml`
* **`[service]`**: Tên service khai báo bên trong file `docker-compose.yml` (dùng khi `<mục_tiêu>` là một dự án nhiều container, ví dụ `mosquitto` trong `~/docker/homeassistant/`). Nếu bỏ trống khi dùng `-r`, `-k`, `-m`, lệnh sẽ áp dụng cho **toàn bộ container** của dự án đó.
* **`[N]`**: Số dòng log muốn hiển thị (nếu không nhập sẽ mặc định lấy **`20`** dòng cuối).
* **`[shell]`**: Đường dẫn shell muốn mở bên trong container (ví dụ `/bin/sh`; mặc định tự thử `/bin/bash` trước rồi mới lùi về `/bin/sh`).

---

### 1. Xem trạng thái & thông tin cấu hình
| Lệnh | Tham số & Ý nghĩa chi tiết | Ví dụ thực tế |
| :--- | :--- | :--- |
| `dps [mục_tiêu]` | Liệt kê container đang chạy (và `restarting` màu đỏ). Bỏ trống để xem tất cả; nhập từ khóa hoặc đường dẫn dự án để lọc. | `dps`<br>`dps wifi`<br>`dps ~/docker/homeassistant/` |
| `dps -a [mục_tiêu]` | Liệt kê **toàn bộ** container kể cả đã dừng/thoát lỗi, bổ sung cột `STATE`, `HEALTH`, `RESTART`, `DISK`. | `dps -a`<br>`dps -a ~/docker/ci-local/` |
| `dps -c <mục_tiêu> [service]` | Xem chi tiết cấu hình 1 container (image gốc, lệnh khởi chạy, file compose, mạng, cổng, mounts). | `dps -c 1`<br>`dps -c ~/docker/homeassistant/ mosquitto` |
| `dps -h` \| `--help` | Hiển thị bảng hướng dẫn sử dụng nhanh ngay trên terminal. | `dps -h` |

### 2. Điều khiển vòng đời & truy cập Container
| Lệnh | Tham số & Ý nghĩa chi tiết | Ví dụ thực tế |
| :--- | :--- | :--- |
| `dps -u [mục_tiêu] [service...] [cờ]` | Chạy `docker compose up -d` tại thư mục hiện tại, hoặc bật dự án/service từ bất kỳ thư mục nào. | `dps -u`<br>`dps -u dozzle`<br>`dps -u ~/docker/homeassistant/ mosquitto --force-recreate` |
| `dps -r <mục_tiêu> [service]` | Khởi động lại (`docker restart`) 1 container, 1 service cụ thể hoặc toàn bộ dự án. | `dps -r mosquitto`<br>`dps -r 2`<br>`dps -r ~/docker/homeassistant/` |
| `dps -k <mục_tiêu> [service]` | Dừng (`docker stop`) container đang chạy theo tên, số `#`, service hoặc cả dự án. | `dps -k dozzle`<br>`dps -k ~/docker/homeassistant/ esphome` |
| `dps -m <mục_tiêu> [service]` | Dừng và xóa hẳn container (`docker rm -f`). | `dps -m 5`<br>`dps -m ~/docker/vnc/` |
| `dps -x <mục_tiêu> [service] [shell]` | Mở giao diện dòng lệnh tương tác bên trong container (`docker exec -it`). | `dps -x 1`<br>`dps -x ~/docker/homeassistant/ mosquitto /bin/sh` |

### 3. Giám sát tài nguyên, tiến trình & sự kiện
| Lệnh | Tham số & Ý nghĩa chi tiết | Ví dụ thực tế |
| :--- | :--- | :--- |
| `dps -s [-a] [mục_tiêu]` | Xem mức tiêu thụ `CPU`, `MEM`, `RESTART`, `DISK`. Thêm `-a` để hiển thị cả container đã dừng. | `dps -s`<br>`dps -s -a ~/docker/homeassistant/` |
| `dps -w [mục_tiêu] [service]` | Mở màn hình giám sát trực tiếp theo thời gian thực (`docker stats`). Bấm `Ctrl + C` để thoát. | `dps -w`<br>`dps -w ~/docker/homeassistant/` |
| `dps -t <mục_tiêu> [service]` | Xem bảng các tiến trình (`PID`, `PPID`, `USER`, `TIME`, `COMMAND`) đang chạy bên trong container (`docker top`). | `dps -t 1`<br>`dps -t ~/docker/homeassistant/ homeassistant` |
| `dps -e [từ_khóa]` | Theo dõi luồng sự kiện Docker thời gian thực (`docker events`). Có thể lọc theo tên container/sự kiện. | `dps -e`<br>`dps -e homeassistant` |

### 4. Kiểm tra Mạng, Lưu trữ & Image
| Lệnh | Tham số & Ý nghĩa chi tiết | Ví dụ thực tế |
| :--- | :--- | :--- |
| `dps -n [tên_mạng]` | Liệt kê các Docker network kèm `DRIVER`, `SUBNET`, `GATEWAY` và danh sách container đang kết nối. | `dps -n`<br>`dps -n wifi-net` |
| `dps -p [mục_tiêu]` | Xem chi tiết mạng của container đang chạy, tách rõ `HOST/EXPOSE PORTS`, `NETWORKS`, `IP` và `PEER`. | `dps -p`<br>`dps -p ~/docker/homeassistant/` |
| `dps -d [-a] [mục_tiêu]` | Kiểm tra dung lượng `DISK`, `VIRTUAL`, đường dẫn `COMPOSE FILE` và chi tiết `MOUNTS`. | `dps -d`<br>`dps -d -a ~/docker/nextcloud-docker/` |
| `dps -i [từ_khóa]` | Liệt kê toàn bộ Docker image kèm trạng thái (`STATE`) và tên container đang dùng (`USED BY`). | `dps -i`<br>`dps -i postgres` |
| `dps -o` | Thống kê tổng quan dung lượng Docker (Images, Containers, Volumes, Build Cache) và volume mồ côi. | `dps -o` |

### 5. Xem nhật ký hoạt động (Logs)
| Lệnh | Tham số & Ý nghĩa chi tiết | Ví dụ thực tế |
| :--- | :--- | :--- |
| `dps -l <mục_tiêu> [service] [N]` | In ra `N` dòng log gần nhất (mặc định `20`) rồi thoát. | `dps -l 1`<br>`dps -l mosquitto 50`<br>`dps -l ~/docker/homeassistant/ homeassistant 100` |
| `dps -f <mục_tiêu> [service] [N]` | In `N` dòng log gần nhất (mặc định `20`) và tiếp tục theo dõi log mới trực tiếp (`--follow`). | `dps -f 1`<br>`dps -f ~/docker/homeassistant/ mosquitto 30` |

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