# dps - Docker PS, Image, Log & Disk Overview CLI (Debian 12) — `v0.0.1`

Ngôn ngữ : [Tiếng Việt](./README.md)  | Language : [English](./README.en.md) | 言語 : [日本語](./README.ja.md) | 语言 : [简体中文](./README.zh.md)


Docker コンテナ、イメージ、設定、ログ、およびシステムディスク使用量を素早く確認するためのコマンドラインツールです。

## クイックインストール（リポジトリディレクトリから）

```bash
chmod +x dps.sh
sudo ln -sf "$(pwd)/dps.sh" /usr/local/bin/dps
sudo cp dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

## 新しいマシンへの移行・インストール手順

1. パッケージ一覧を更新し、`git`、`python3`、`bash-completion`（未インストールの場合）を導入してリポジトリをクローンします：

```bash
sudo apt-get update
sudo apt-get install -y git
sudo apt-get install -y python3 bash-completion
git clone https://github.com/vanhoacdt/docker-cli.git ~/dps-cli
cd ~/dps-cli
```

2. `dps` コマンドのシンボリックリンクを作成し、タブ補完を有効化します：

```bash
chmod +x ~/dps-cli/dps.sh
sudo ln -sf ~/dps-cli/dps.sh /usr/local/bin/dps
sudo cp ~/dps-cli/dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

3. 移行後の動作確認を行います：

```bash
which dps && dps -h
```

## GitHub への変更反映

1. リポジトリディレクトリへ移動し、変更されたファイルを確認します：

```bash
cd ~/dps-cli
git status
```

2. 変更をステージングし、コミットを作成して GitHub の `main` ブランチへプッシュします：

```bash
git add .
git commit -m "chore: update dps cli"
git push origin main
```

3. 補完ファイルを編集した場合は、タブ補完を再読み込みします：

```bash
sudo cp ~/dps-cli/dps.bash-completion /etc/bash_completion.d/dps
source /etc/bash_completion.d/dps
```

## システムからのアンインストール

1. 現在のシェルセッションのタブ補完を解除し、`~/dps-cli` ディレクトリの外へ移動します：

```bash
complete -r dps 2>/dev/null || true
cd ~
```

2. コマンドのシンボリックリンク、補完ファイル、およびソースコードディレクトリを削除します：

```bash
sudo rm -f /usr/local/bin/dps
sudo rm -f /etc/bash_completion.d/dps
rm -rf ~/dps-cli
```

3. アンインストール完了を確認します：

```bash
which dps 2>/dev/null || echo "dps をアンインストールしました"
```

## 使い方

### 引数・パラメータの表記ルール
* **`[...]`（角括弧）**: **省略可能**なオプション引数です。
* **`<...>`（山括弧）**: **必須**引数です（少なくとも1つの値を指定する必要があります）。
* **`<ターゲット>`**: どのディレクトリからでも以下の **4つの形式** のいずれかを指定できます：
  1. **コンテナ名**（または検索キーワード）: `mosquitto`, `wifi`
  2. **`dps` テーブルの `#` 番号**: `1`, `3`
  3. **`~/docker/` 内のプロジェクト名**: `homeassistant`, `dozzle`
  4. **プロジェクトディレクトリまたは `docker-compose.yml` のパス**: `~/docker/homeassistant/`, `./docker-compose.yml`
* **`[service]`**: `docker-compose.yml` 内に定義されたサービス名（`<ターゲット>` に複数コンテナを持つプロジェクトを指定した場合に使用。例: `~/docker/homeassistant/` 内の `mosquitto`）。`-r`、`-k`、`-m` でサービス名を省略すると、そのプロジェクトの **全コンテナ** に対して実行されます。
* **`[N]`**: 表示するログの行数（省略時はデフォルトで末尾 **`20`** 行を表示します）。
* **`[shell]`**: コンテナ内で起動するシェルのパス（例: `/bin/sh`。省略時は `/bin/bash` を優先し、なければ `/bin/sh` を使用します）。

---

### 1. 状態確認・設定インスペクト
| コマンド | 引数と機能の詳細 | 使用例 |
| :--- | :--- | :--- |
| `dps [ターゲット]` | 稼働中および `restarting`（赤色表示）のコンテナを一覧表示します。省略時は全件、キーワードやプロジェクトパス指定で絞り込みます。 | `dps`<br>`dps wifi`<br>`dps ~/docker/homeassistant/` |
| `dps -a [ターゲット]` | 停止中・異常終了を含む**すべて**のコンテナを表示し、`STATE`、`HEALTH`、`RESTART`、`DISK` 列を追加します。 | `dps -a`<br>`dps -a ~/docker/ci-local/` |
| `dps -c <ターゲット> [service]` | 1つのコンテナの詳細設定（イメージ、起動コマンド、Compose ファイル、ネットワーク、ポート、マウント）を表示します。 | `dps -c 1`<br>`dps -c ~/docker/homeassistant/ mosquitto` |
| `dps -h` \| `--help` | ターミナル上にクイックヘルプを表示します。 | `dps -h` |

### 2. ライフサイクル操作・コンテナ接続
| コマンド | 引数と機能の詳細 | 使用例 |
| :--- | :--- | :--- |
| `dps -u [ターゲット] [service...] [オプション]` | 現在のディレクトリで `docker compose up -d` を実行、または任意の場所からプロジェクト／サービスを起動します。 | `dps -u`<br>`dps -u dozzle`<br>`dps -u ~/docker/homeassistant/ mosquitto --force-recreate` |
| `dps -r <ターゲット> [service]` | 単一コンテナ、特定サービス、またはプロジェクト全体を再起動（`docker restart`）します。 | `dps -r mosquitto`<br>`dps -r 2`<br>`dps -r ~/docker/homeassistant/` |
| `dps -k <ターゲット> [service]` | コンテナ名、`#` 番号、サービス名、またはプロジェクト全体を指定して稼働中コンテナを停止（`docker stop`）します。 | `dps -k dozzle`<br>`dps -k ~/docker/homeassistant/ esphome` |
| `dps -m <ターゲット> [service]` | コンテナを強制停止して削除（`docker rm -f`）します。 | `dps -m 5`<br>`dps -m ~/docker/vnc/` |
| `dps -x <ターゲット> [service] [shell]` | コンテナ内で対話シェル（`docker exec -it`）を開きます。 | `dps -x 1`<br>`dps -x ~/docker/homeassistant/ mosquitto /bin/sh` |

### 3. リソース・プロセス・イベント監視
| コマンド | 引数と機能の詳細 | 使用例 |
| :--- | :--- | :--- |
| `dps -s [-a] [ターゲット]` | `CPU`、`MEM`、`RESTART`、`DISK` 使用量を表示します（`-a` を付けると停止中コンテナも対象）。 | `dps -s`<br>`dps -s -a ~/docker/homeassistant/` |
| `dps -w [ターゲット] [service]` | リアルタイムのリソース監視（`docker stats`）を起動します。`Ctrl + C` で終了します。 | `dps -w`<br>`dps -w ~/docker/homeassistant/` |
| `dps -t <ターゲット> [service]` | コンテナ内の実行中プロセス（`PID`、`PPID`、`USER`、`TIME`、`COMMAND`）を表示します（`docker top`）。 | `dps -t 1`<br>`dps -t ~/docker/homeassistant/ homeassistant` |
| `dps -e [キーワード]` | Docker イベントをリアルタイム監視（`docker events`）します。コンテナ名やイベント名でフィルタ可能です。 | `dps -e`<br>`dps -e homeassistant` |

### 4. ネットワーク・ストレージ・イメージ確認
| コマンド | 引数と機能の詳細 | 使用例 |
| :--- | :--- | :--- |
| `dps -n [ネットワーク名]` | Docker ネットワーク一覧と `DRIVER`、`SUBNET`、`GATEWAY`、接続中コンテナを表示します。 | `dps -n`<br>`dps -n wifi-net` |
| `dps -p [ターゲット]` | 稼働中コンテナの詳細ネットワーク構成（`HOST/EXPOSE PORTS`、`NETWORKS`、`IP`、`PEER`）を表示します。 | `dps -p`<br>`dps -p ~/docker/homeassistant/` |
| `dps -d [-a] [ターゲット]` | ディスク使用量（`DISK`、`VIRTUAL`）、参照元 `COMPOSE FILE`、`MOUNTS` 詳細を表示します。 | `dps -d`<br>`dps -d -a ~/docker/nextcloud-docker/` |
| `dps -i [キーワード]` | 全 Docker イメージ一覧と使用状況（`STATE`、`USED BY`）を表示します。 | `dps -i`<br>`dps -i postgres` |
| `dps -o` | Docker 全体のディスク使用サマリー（`Images`、`Containers`、`Local Volumes`、`Build Cache`）と孤立ボリュームを表示します。 | `dps -o` |

### 5. コンテナログ表示
| コマンド | 引数と機能の詳細 | 使用例 |
| :--- | :--- | :--- |
| `dps -l <ターゲット> [service] [N]` | 最新 `N` 行のログ（デフォルト `20` 行）を表示して終了します。 | `dps -l 1`<br>`dps -l mosquitto 50`<br>`dps -l ~/docker/homeassistant/ homeassistant 100` |
| `dps -f <ターゲット> [service] [N]` | 最新 `N` 行のログ（デフォルト `20` 行）を表示し、新しいログをリアルタイム追跡（`--follow`）します。 | `dps -f 1`<br>`dps -f ~/docker/homeassistant/ mosquitto 30` |

## タブ補完（Tab Completion）＆スマートターゲット解決の仕組み

**`Tab`** キーを押すことで、どのディレクトリにいても各オプションの文脈に応じた自動補完が機能します：

- **フラグ＆コンテナ名の候補表示:** `dps -` + `Tab` で全オプション一覧を、`dps ` + `Tab` で稼働中のコンテナ名および `~/docker/` 内のプロジェクト名を候補表示します。
- **オプション別の文脈補完:**
  - `dps -r`、`-k`、`-m`、`-t`、`-x`、`-l`、`-f`、`-w`: 稼働中のコンテナ名、`~/docker/` 内のプロジェクト名、ディレクトリ／ファイルパスを補完します。
  - `dps -c`、`-a`、`-s`、`-d`、`-p`、`-e`: 停止中を含む全コンテナ名、プロジェクト名、パスを補完します。
  - `dps -n`: 既存の Docker ネットワーク名を補完します。
  - `dps -i`: Docker イメージのリポジトリ名を補完します。
- **Compose プロジェクトの多段階補完（`-u` および各操作コマンド）:**
  1. **`docker-compose.yml` があるディレクトリ内にいる場合:** `dps -u ` の後に `Tab` を押すと、そのファイルに定義された **service** 名を候補表示します。
  2. **外部の任意のディレクトリにいる場合:** `dps -u `（または `-r`、`-k`、`-l`、`-x` など）の後に `Tab` を押すと、`~/docker/` 配下の**プロジェクト名**（例: `homeassistant`、`dozzle`、`ci-local`）またはディレクトリパス（`~/docker/homeassistant/`）を補完します。
  3. **プロジェクト内のサービス連続補完:** プロジェクト名またはパスを入力した状態（例: `dps -u ~/docker/homeassistant/ ` や `dps -r homeassistant `）でもう一度 `Tab` を押すと、対象 Compose ファイルを自動解析して各 **service** 名を候補表示します（`-u` の場合は `--force-recreate`、`--build`、`--no-deps` などのフラグも補完されます）。