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

- `dps [关键词]` — 查看容器列表（`CONTAINER`、`STATUS`、`RESTART`、`DISK`、`PORTS`、`NETWORKS`）
- `dps -s` — 查看 `CPU`、`MEM`、`RESTART`、`DISK`
- `dps -w [容器名]` — 直接运行 `docker stats`
- `dps -e <容器> [shell]` — 打开交互式终端 `docker exec -it`（`/bin/bash` -> `/bin/sh`）
- `dps -d [关键词]` — 查看 `DISK`、`VIRTUAL`、`COMPOSE FILE` 和 `MOUNTS`
- `dps -p [关键词]` — 查看运行中容器 + 分离显示 `HOST/EXPOSE PORTS`、`NETWORKS`、`IP`、`PEER`
- `dps -i [关键词]` — 查看 Docker 镜像列表，附带 `STATE` 和 `USED BY` 列
- `dps -c <名称或#>` — 查看单个容器的配置、网络、挂载和 Compose 信息
- `dps -o` — 查看 `Images`、`Containers`、`Local Volumes`、`Build Cache` 及悬空卷空间概览
- `dps -l <名称或#> [N]` — 查看末尾 `N` 行日志（默认 40）
- `dps -f <名称或#> [N]` — 实时跟踪末尾 `N` 行日志（默认 40）
- `dps -h` — 查看帮助