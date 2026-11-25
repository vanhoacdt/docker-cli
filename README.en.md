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

- `dps [keyword]` — List running containers (`CONTAINER`, `STATUS`, `PORTS`, `NETWORKS`)
- `dps -a [keyword]` — List all containers including stopped ones (same format as `dps`)
- `dps -u [service...]` — Run `docker compose up -d` in the current directory
- `dps -r <name_or_#>` — Restart (`docker restart`) a container by name or index `#`
- `dps -k <name_or_#>` — Stop (`docker stop`) a container by name or index `#`
- `dps -m <name_or_#>` — Force remove (`docker rm -f`) a container by name or index `#`
- `dps -n [network_name]` — List Docker networks, subnets, gateways & connected containers
- `dps -t <name_or_#>` — Display running processes inside a container (`docker top`)
- `dps -s [-a]` — View `CPU`, `MEM`, `RESTART`, `DISK` (add `-a` to include stopped containers)
- `dps -w [container_name]` — Run `docker stats` directly
- `dps -x <container> [shell]` — Open interactive `docker exec -it` shell (`/bin/bash` -> `/bin/sh`)
- `dps -e [keyword]` — Stream real-time Docker daemon events (`docker events`)
- `dps -d [-a] [keyword]` — View `DISK`, `VIRTUAL`, `COMPOSE FILE`, and `MOUNTS`
- `dps -p [keyword]` — View running containers with split `HOST/EXPOSE PORTS`, `NETWORKS`, `IP`, `PEER`
- `dps -i [keyword]` — List Docker images with `STATE` and `USED BY` columns
- `dps -c <name_or_#>` — Show config, network, mount, and compose details for a single container
- `dps -o` — Disk usage overview for `Images`, `Containers`, `Local Volumes`, `Build Cache` & orphan volumes
- `dps -l <name_or_#> [N]` — View last `N` log lines (default 20)
- `dps -f <name_or_#> [N]` — Follow last `N` live log lines (default 20)
- `dps -h` — Help

## Tab Completion & Smart Target Resolution Mechanism

Pressing **`Tab`** provides context-aware auto-completion across all flags from any working directory:

- **Flag & Container Suggestions:** Type `dps -` + `Tab` to list all CLI options; type `dps ` + `Tab` to suggest running container names and project names inside `~/docker/`.
- **Flag-Specific Context Completion:**
  - `dps -r`, `-k`, `-m`, `-t`, `-x`, `-l`, `-f`, `-w`: Completes running containers, project names in `~/docker/`, and directory/file paths.
  - `dps -c`, `-a`, `-s`, `-d`, `-p`, `-e`: Completes all containers (including stopped ones), project names, and paths.
  - `dps -n`: Completes existing Docker network names.
  - `dps -i`: Completes Docker image repository names.
- **Multi-Level Compose Project Completion (`-u` and other flags):**
  1. **Inside a directory containing `docker-compose.yml`:** Pressing `Tab` after `dps -u ` suggests the **service** names defined in that compose file.
  2. **From any external directory:** Pressing `Tab` after `dps -u ` (or `-r`, `-k`, `-l`, `-x`, etc.) suggests **project** folder names located in `~/docker/` (e.g., `homeassistant`, `dozzle`, `ci-local`) or completes directory paths (`~/docker/homeassistant/`).
  3. **Chained Service Completion:** Once a project name or path is entered (e.g., `dps -u ~/docker/homeassistant/ ` or `dps -r homeassistant `), pressing `Tab` again parses the target compose file and suggests its individual **services** (along with flags like `--force-recreate`, `--build`, `--no-deps` for `-u`).