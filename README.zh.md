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

- `dps [关键词]` — 查看运行中容器列表（`CONTAINER`、`STATUS`、`PORTS`、`NETWORKS`）
- `dps -a [关键词]` — 查看所有容器（包括已停止的容器，格式与 `dps` 相同）
- `dps -u [service...]` — 在当前目录执行 `docker compose up -d`
- `dps -r <名称或#>` — 按名称或序号 `#` 重启容器（`docker restart`）
- `dps -k <名称或#>` — 按名称或序号 `#` 停止容器（`docker stop`）
- `dps -m <名称或#>` — 按名称或序号 `#` 强制删除容器（`docker rm -f`）
- `dps -n [网络名称]` — 查看 Docker 网络、子网、网关及已连接的容器
- `dps -t <名称或#>` — 查看容器内正在运行的进程（`docker top`）
- `dps -s [-a]` — 查看 `CPU`、`MEM`、`RESTART`、`DISK`（添加 `-a` 可同时查看已停止容器）
- `dps -w [容器名]` — 直接运行 `docker stats`
- `dps -x <容器> [shell]` — 打开交互式终端 `docker exec -it`（`/bin/bash` -> `/bin/sh`）
- `dps -e [关键词]` — 实时监控 Docker 守护进程事件（`docker events`）
- `dps -d [-a] [关键词]` — 查看 `DISK`、`VIRTUAL`、`COMPOSE FILE` 和 `MOUNTS`
- `dps -p [关键词]` — 查看运行中容器 + 分离显示 `HOST/EXPOSE PORTS`、`NETWORKS`、`IP`、`PEER`
- `dps -i [关键词]` — 查看 Docker 镜像列表，附带 `STATE` 和 `USED BY` 列
- `dps -c <名称或#>` — 查看单个容器的配置、网络、挂载和 Compose 信息
- `dps -o` — 查看 `Images`、`Containers`、`Local Volumes`、`Build Cache` 及悬空卷空间概览
- `dps -l <名称或#> [N]` — 查看末尾 `N` 行日志（默认 20）
- `dps -f <名称或#> [N]` — 实时跟踪末尾 `N` 行日志（默认 20）
- `dps -h` — 查看帮助

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