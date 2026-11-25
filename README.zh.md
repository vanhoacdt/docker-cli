# dps - Docker PS, Image, Log & Disk Overview CLI (Debian 12) — `v0.0.1`

Ngôn ngữ : [Tiếng Việt](./README.md)  | Language : [English](./README.en.md) | 言語 : [日本語](./README.ja.md) | 语言 : [简体中文](./README.zh.md)

用于在 Debian 12 上快速查看 Docker 容器、镜像、配置、日志和系统磁盘占用情况的命令行工具。

## 快速安装（从仓库目录）

```bash
chmod +x dps.sh
sudo ln -sf "$(pwd)/dps.sh" /usr/local/bin/dps
sudo cp dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

## 迁移到新机器时的安装步骤

1. 更新软件包列表，安装 `git`、`python3` 和 `bash-completion`（若新机器尚未安装），然后克隆仓库：

```bash
sudo apt-get update
sudo apt-get install -y git
sudo apt-get install -y python3 bash-completion
git clone https://github.com/vanhoacdt/docker-cli.git ~/dps-cli
cd ~/dps-cli
```

2. 链接 `dps` 命令并启用 Tab 自动补全：

```bash
chmod +x ~/dps-cli/dps.sh
sudo ln -sf ~/dps-cli/dps.sh /usr/local/bin/dps
sudo cp ~/dps-cli/dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

3. 迁移后快速检查：

```bash
which dps && dps -h
```

## 推送更改到 GitHub

1. 进入仓库目录并查看已修改的文件：

```bash
cd ~/dps-cli
git status
```

2. 暂存更改、提交并推送到 GitHub 的 `main` 分支：

```bash
git add .
git commit -m "chore: update dps cli"
git push origin main
```

3. 如果修改了自动补全脚本，请重新加载：

```bash
sudo cp ~/dps-cli/dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

## 从系统卸载

1. 在当前 Shell 会话中移除 `dps` 自动补全并离开 `~/dps-cli` 目录（若当前位于该目录内）：

```bash
complete -r dps 2>/dev/null || true
cd ~
```

2. 删除命令软链接、自动补全文件和源码目录：

```bash
sudo rm -f /usr/local/bin/dps
sudo rm -f /etc/bash_completion.d/dps
rm -rf ~/dps-cli
```

3. 卸载后验证：

```bash
which dps 2>/dev/null || echo "已卸载 dps"
```

## 使用方法

### 参数符号约定
* **`[...]`（方括号）**：**可选**参数 — 可以省略。
* **`<...>`（尖括号）**：**必填**参数 — 必须提供至少一个值。
* **`<目标>`**：可在任意目录下灵活传入以下 **4 种格式之一**：
  1. **容器名称**（或过滤关键词）：`mosquitto`、`wifi`
  2. **`dps` 表格中的 `#` 序号**：`1`、`3`
  3. **`~/docker/` 下的项目名称**：`homeassistant`、`dozzle`
  4. **项目目录路径或 `docker-compose.yml` 文件路径**：`~/docker/homeassistant/`、`./docker-compose.yml`
* **`[service]`**：`docker-compose.yml` 中定义的服务名（当 `<目标>` 为包含多个容器的项目时使用，例如 `~/docker/homeassistant/` 中的 `mosquitto`）。在使用 `-r`、`-k`、`-m` 时若省略此参数，则对**该项目下的所有容器**生效。
* **`[N]`**：要显示的日志行数（省略时默认输出末尾 **`20`** 行）。
* **`[shell]`**：在容器内启动的 Shell 路径（例如 `/bin/sh`；默认优先尝试 `/bin/bash`，不存在时自动回退至 `/bin/sh`）。

---

### 1. 状态查看与配置检查
| 命令 | 参数与功能详细说明 | 实用示例 |
| :--- | :--- | :--- |
| `dps [目标]` | 列出运行中及 `restarting`（红色高亮）的容器。留空显示全部；传入关键词或项目路径可筛选。 | `dps`<br>`dps wifi`<br>`dps ~/docker/homeassistant/` |
| `dps -a [目标]` | 列出**所有**容器（含已停止/异常退出），额外显示 `STATE`、`HEALTH`、`RESTART`、`DISK` 列。 | `dps -a`<br>`dps -a ~/docker/ci-local/` |
| `dps -c <目标> [service]` | 查看单个容器的完整配置（镜像、启动命令、Compose 文件、网络、端口、挂载卷）。 | `dps -c 1`<br>`dps -c ~/docker/homeassistant/ mosquitto` |
| `dps -h` \| `--help` | 在终端中显示快速帮助菜单。 | `dps -h` |

### 2. 生命周期控制与容器交互
| 命令 | 参数与功能详细说明 | 实用示例 |
| :--- | :--- | :--- |
| `dps -u [目标] [service...] [参数]` | 在当前目录执行 `docker compose up -d`，或从任意目录按路径/项目名启动指定项目及服务。 | `dps -u`<br>`dps -u dozzle`<br>`dps -u ~/docker/homeassistant/ mosquitto --force-recreate` |
| `dps -r <目标> [service]` | 重启（`docker restart`）单个容器、指定服务或整个项目。 | `dps -r mosquitto`<br>`dps -r 2`<br>`dps -r ~/docker/homeassistant/` |
| `dps -k <目标> [service]` | 按名称、序号 `#`、服务名或整个项目停止运行中的容器（`docker stop`）。 | `dps -k dozzle`<br>`dps -k ~/docker/homeassistant/ esphome` |
| `dps -m <目标> [service]` | 强制停止并删除容器（`docker rm -f`）。 | `dps -m 5`<br>`dps -m ~/docker/vnc/` |
| `dps -x <目标> [service] [shell]` | 打开容器内的交互式终端（`docker exec -it`）。 | `dps -x 1`<br>`dps -x ~/docker/homeassistant/ mosquitto /bin/sh` |

### 3. 资源、进程与事件监控
| 命令 | 参数与功能详细说明 | 实用示例 |
| :--- | :--- | :--- |
| `dps -s [-a] [目标]` | 查看 `CPU`、`MEM`、`RESTART`、`DISK` 资源占用（加 `-a` 包含已停止容器）。 | `dps -s`<br>`dps -s -a ~/docker/homeassistant/` |
| `dps -w [目标] [service]` | 启动实时资源监控界面（`docker stats`），按 `Ctrl + C` 退出。 | `dps -w`<br>`dps -w ~/docker/homeassistant/` |
| `dps -t <目标> [service]` | 查看容器内正在运行的进程（`PID`、`PPID`、`USER`、`TIME`、`COMMAND`）（`docker top`）。 | `dps -t 1`<br>`dps -t ~/docker/homeassistant/ homeassistant` |
| `dps -e [关键词]` | 实时监听 Docker 守护进程事件（`docker events`），支持按容器名或事件关键词过滤。 | `dps -e`<br>`dps -e homeassistant` |

### 4. 网络、存储与镜像检查
| 命令 | 参数与功能详细说明 | 实用示例 |
| :--- | :--- | :--- |
| `dps -n [网络名称]` | 列出 Docker 网络及 `DRIVER`、`SUBNET`、`GATEWAY` 和已连接的容器。 | `dps -n`<br>`dps -n wifi-net` |
| `dps -p [目标]` | 查看运行中容器的详细网络连接，拆分显示 `HOST/EXPOSE PORTS`、`NETWORKS`、`IP` 与 `PEER`。 | `dps -p`<br>`dps -p ~/docker/homeassistant/` |
| `dps -d [-a] [目标]` | 查看磁盘占用（`DISK`、`VIRTUAL`）、来源 `COMPOSE FILE` 路径及 `MOUNTS` 挂载详情。 | `dps -d`<br>`dps -d -a ~/docker/nextcloud-docker/` |
| `dps -i [关键词]` | 列出所有 Docker 镜像及其使用状态（`STATE`）和关联容器（`USED BY`）。 | `dps -i`<br>`dps -i postgres` |
| `dps -o` | 查看 Docker 整体磁盘占用概览（`Images`、`Containers`、`Local Volumes`、`Build Cache`）及悬空卷。 | `dps -o` |

### 5. 容器日志查看
| 命令 | 参数与功能详细说明 | 实用示例 |
| :--- | :--- | :--- |
| `dps -l <目标> [service] [N]` | 输出最近 `N` 行日志（默认 `20` 行）并退出。 | `dps -l 1`<br>`dps -l mosquitto 50`<br>`dps -l ~/docker/homeassistant/ homeassistant 100` |
| `dps -f <目标> [service] [N]` | 输出最近 `N` 行日志（默认 `20` 行）并持续追踪实时新日志（`--follow`）。 | `dps -f 1`<br>`dps -f ~/docker/homeassistant/ mosquitto 30` |

## Tab 自动补全与智能目标解析机制

无论当前处于哪个目录，按下 **`Tab`** 键均可根据命令参数提供上下文感知的智能补全：

- **参数与容器即时提示：** 输入 `dps -` 后按 `Tab` 列出所有可用参数；输入 `dps ` + `Tab` 自动提示正在运行的容器名及 `~/docker/` 下的项目名称。
- **按参数区分上下文补全：**
  - `dps -r`、`-k`、`-m`、`-t`、`-x`、`-l`、`-f`、`-w`：自动补全运行中的容器名、`~/docker/` 下的项目名以及目录/文件路径。
  - `dps -c`、`-a`、`-s`、`-d`、`-p`、`-e`：自动补全所有容器（含已停止容器）、项目名及文件路径。
  - `dps -n`：自动补全现有的 Docker 网络名称。
  - `dps -i`：自动补全 Docker 镜像仓库名称。
- **Compose 项目多级联动补全（`-u` 及其他操作命令）：**
  1. **位于包含 `docker-compose.yml` 的目录内时：** 在 `dps -u ` 后按 `Tab`，直接提示该 Compose 文件中定义的各个 **service** 名称。
  2. **位于外部任意目录时：** 在 `dps -u `（或 `-r`、`-k`、`-l`、`-x` 等）后按 `Tab`，自动提示 `~/docker/` 目录下的**项目名称**（如 `homeassistant`、`dozzle`、`ci-local`）或补全目录路径（如 `~/docker/homeassistant/`）。
  3. **项目内服务名二级补全：** 输入项目名或目录路径后（例如 `dps -u ~/docker/homeassistant/ ` 或 `dps -r homeassistant `），再次按 `Tab` 会自动解析目标 Compose 文件并提示其内部的各个 **service** 名称（使用 `-u` 时还会同时提示 `--force-recreate`、`--build`、`--no-deps` 等常用参数）。