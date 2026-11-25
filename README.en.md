# dps - Docker PS, Image, Log & Disk Overview CLI (Debian 12) — `v0.0.1`

Ngôn ngữ : [Tiếng Việt](./README.md)  | Language : [English](./README.en.md) | 言語 : [日本語](./README.ja.md) | 语言 : [简体中文](./README.zh.md)


Command-line utility for quickly inspecting Docker containers, images, configurations, logs, and system disk usage.

## Quick Install (from repository directory)

```bash
chmod +x dps.sh
sudo ln -sf "$(pwd)/dps.sh" /usr/local/bin/dps
sudo cp dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

## Installation on a New Machine

1. Update package lists, install `git`, `python3`, and `bash-completion` (if not already installed), then clone the repository:

```bash
sudo apt-get update
sudo apt-get install -y git
sudo apt-get install -y python3 bash-completion
git clone https://github.com/vanhoacdt/docker-cli.git ~/dps-cli
cd ~/dps-cli
```

2. Symlink the `dps` command and enable tab completion:

```bash
chmod +x ~/dps-cli/dps.sh
sudo ln -sf ~/dps-cli/dps.sh /usr/local/bin/dps
sudo cp ~/dps-cli/dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

3. Verify the setup on the new machine:

```bash
which dps && dps -h
```

## Pushing Changes to GitHub

1. Navigate to the repository directory and check modified files:

```bash
cd ~/dps-cli
git status
```

2. Stage changes, create a commit, and push to the `main` branch on GitHub:

```bash
git add .
git commit -m "chore: update dps cli"
git push origin main
```

3. Reload completion if you modified the completion script:

```bash
sudo cp ~/dps-cli/dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

## Uninstalling from the System

1. Unregister tab completion in the current shell session and move outside `~/dps-cli` (if currently inside):

```bash
complete -r dps 2>/dev/null || true
cd ~
```

2. Remove the command symlink, completion file, and source directory:

```bash
sudo rm -f /usr/local/bin/dps
sudo rm -f /etc/bash_completion.d/dps
rm -rf ~/dps-cli
```

3. Verify removal:

```bash
which dps 2>/dev/null || echo "Uninstalled dps"
```

## Usage

- `dps [keyword]` — List running containers (`CONTAINER`, `STATUS`, `RESTART`, `DISK`, `PORTS`, `NETWORKS`)
- `dps -a [keyword]` — List all containers including stopped ones (same format as `dps`)
- `dps -s [-a]` — View `CPU`, `MEM`, `RESTART`, `DISK` (add `-a` to include stopped containers)
- `dps -w [container_name]` — Run `docker stats` directly
- `dps -e <container> [shell]` — Open interactive `docker exec -it` shell (`/bin/bash` -> `/bin/sh`)
- `dps -d [-a] [keyword]` — View `DISK`, `VIRTUAL`, `COMPOSE FILE`, and `MOUNTS`
- `dps -p [keyword]` — View running containers with split `HOST/EXPOSE PORTS`, `NETWORKS`, `IP`, `PEER`
- `dps -i [keyword]` — List Docker images with `STATE` and `USED BY` columns
- `dps -c <name_or_#>` — Show config, network, mount, and compose details for a single container
- `dps -o` — Disk usage overview for `Images`, `Containers`, `Local Volumes`, `Build Cache` & orphan volumes
- `dps -l <name_or_#> [N]` — View last `N` log lines (default 20)
- `dps -f <name_or_#> [N]` — Follow last `N` live log lines (default 20)
- `dps -h` — Help