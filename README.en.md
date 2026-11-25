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

### Argument Conventions
* **`[...]` (Square brackets)**: **Optional** argument — can be omitted.
* **`<...>` (Angle brackets)**: **Required** argument — at least one value must be provided.
* **`<target>`**: Accepts **any of 4 formats** from any working directory:
  1. **Container name** (or filter keyword): `mosquitto`, `wifi`
  2. **Row index `#`** from the `dps` table: `1`, `3`
  3. **Project name inside `~/docker/`**: `homeassistant`, `dozzle`
  4. **Project directory path or `docker-compose.yml` file path**: `~/docker/homeassistant/`, `./docker-compose.yml`
* **`[service]`**: Service name defined inside `docker-compose.yml` (used when `<target>` points to a multi-container project, e.g., `mosquitto` inside `~/docker/homeassistant/`). When omitted on `-r`, `-k`, or `-m`, the action applies to **all containers** in that project.
* **`[N]`**: Number of log lines to display (defaults to **`20`** lines if omitted).
* **`[shell]`**: Shell binary path to launch inside the container (e.g., `/bin/sh`; defaults to trying `/bin/bash` first and falling back to `/bin/sh`).

---

### 1. Status & Configuration Inspection
| Command | Arguments & Detailed Meaning | Practical Examples |
| :--- | :--- | :--- |
| `dps [target]` | List running containers (and `restarting` in red). Omit `<target>` to show all; pass a keyword or project path to filter. | `dps`<br>`dps wifi`<br>`dps ~/docker/homeassistant/` |
| `dps -a [target]` | List **all** containers including stopped/exited ones, adding `STATE`, `HEALTH`, `RESTART`, and `DISK` columns. | `dps -a`<br>`dps -a ~/docker/ci-local/` |
| `dps -c <target> [service]` | Inspect full configuration details for a single container (image, entrypoint/cmd, compose file, networks, ports, mounts). | `dps -c 1`<br>`dps -c ~/docker/homeassistant/ mosquitto` |
| `dps -h` \| `--help` | Display the quick help reference in the terminal. | `dps -h` |

### 2. Lifecycle Control & Container Access
| Command | Arguments & Detailed Meaning | Practical Examples |
| :--- | :--- | :--- |
| `dps -u [target] [service...] [flags]` | Run `docker compose up -d` in the current directory, or start a project/service from any directory. | `dps -u`<br>`dps -u dozzle`<br>`dps -u ~/docker/homeassistant/ mosquitto --force-recreate` |
| `dps -r <target> [service]` | Restart (`docker restart`) a single container, a specific service, or an entire project. | `dps -r mosquitto`<br>`dps -r 2`<br>`dps -r ~/docker/homeassistant/` |
| `dps -k <target> [service]` | Stop (`docker stop`) a running container by name, index `#`, service, or an entire project. | `dps -k dozzle`<br>`dps -k ~/docker/homeassistant/ esphome` |
| `dps -m <target> [service]` | Force-stop and remove container(s) (`docker rm -f`). | `dps -m 5`<br>`dps -m ~/docker/vnc/` |
| `dps -x <target> [service] [shell]` | Open an interactive shell inside a container (`docker exec -it`). | `dps -x 1`<br>`dps -x ~/docker/homeassistant/ mosquitto /bin/sh` |

### 3. Resource, Process & Event Monitoring
| Command | Arguments & Detailed Meaning | Practical Examples |
| :--- | :--- | :--- |
| `dps -s [-a] [target]` | View `CPU`, `MEM`, `RESTART`, and `DISK` usage. Add `-a` to include stopped containers. | `dps -s`<br>`dps -s -a ~/docker/homeassistant/` |
| `dps -w [target] [service]` | Launch real-time resource monitoring (`docker stats`). Press `Ctrl + C` to exit. | `dps -w`<br>`dps -w ~/docker/homeassistant/` |
| `dps -t <target> [service]` | View running processes (`PID`, `PPID`, `USER`, `TIME`, `COMMAND`) inside a container (`docker top`). | `dps -t 1`<br>`dps -t ~/docker/homeassistant/ homeassistant` |
| `dps -e [keyword]` | Stream real-time Docker daemon events (`docker events`). Optionally filter by container or event keyword. | `dps -e`<br>`dps -e homeassistant` |

### 4. Network, Storage & Image Inspection
| Command | Arguments & Detailed Meaning | Practical Examples |
| :--- | :--- | :--- |
| `dps -n [network_name]` | List Docker networks with `DRIVER`, `SUBNET`, `GATEWAY`, and connected containers. | `dps -n`<br>`dps -n wifi-net` |
| `dps -p [target]` | View detailed network topology for running containers (`HOST/EXPOSE PORTS`, `NETWORKS`, `IP`, `PEER`). | `dps -p`<br>`dps -p ~/docker/homeassistant/` |
| `dps -d [-a] [target]` | Inspect disk usage (`DISK`, `VIRTUAL`), source `COMPOSE FILE` path, and `MOUNTS` details. | `dps -d`<br>`dps -d -a ~/docker/nextcloud-docker/` |
| `dps -i [keyword]` | List all Docker images with `STATE` and `USED BY` container names. | `dps -i`<br>`dps -i postgres` |
| `dps -o` | Show overall Docker disk summary (`Images`, `Containers`, `Local Volumes`, `Build Cache`) and orphan volumes. | `dps -o` |

### 5. Container Logs
| Command | Arguments & Detailed Meaning | Practical Examples |
| :--- | :--- | :--- |
| `dps -l <target> [service] [N]` | Print the last `N` log lines (default `20`) and exit. | `dps -l 1`<br>`dps -l mosquitto 50`<br>`dps -l ~/docker/homeassistant/ homeassistant 100` |
| `dps -f <target> [service] [N]` | Print the last `N` log lines (default `20`) and follow new logs in real time (`--follow`). | `dps -f 1`<br>`dps -f ~/docker/homeassistant/ mosquitto 30` |

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