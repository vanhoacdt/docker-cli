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

- `dps [キーワード]` — 稼働中コンテナ一覧（`CONTAINER`、`STATUS`、`PORTS`、`NETWORKS`）
- `dps -a [キーワード]` — 停止中を含むすべてのコンテナ一覧（`dps` と同じ形式）
- `dps -u [service...]` — 現在のディレクトリで `docker compose up -d` を実行
- `dps -r <名前または#>` — コンテナ名または番号 `#` を指定して再起動（`docker restart`）
- `dps -k <名前または#>` — コンテナ名または番号 `#` を指定して停止（`docker stop`）
- `dps -m <名前または#>` — コンテナ名または番号 `#` を指定して強制削除（`docker rm -f`）
- `dps -n [ネットワーク名]` — Docker ネットワーク、サブネット、ゲートウェイ、接続中コンテナ一覧
- `dps -t <名前または#>` — コンテナ内の実行中プロセスを表示（`docker top`）
- `dps -s [-a]` — `CPU`、`MEM`、`RESTART`、`DISK` を表示（`-a` 追加で停止中コンテナも表示）
- `dps -w [コンテナ名]` — `docker stats` を直接実行
- `dps -x <container> [shell]` — 対話シェル `docker exec -it` を起動（`/bin/bash` -> `/bin/sh`）
- `dps -e [キーワード]` — Docker イベントをリアルタイム監視（`docker events`）
- `dps -d [-a] [キーワード]` — `DISK`、`VIRTUAL`、`COMPOSE FILE`、`MOUNTS` を表示
- `dps -p [キーワード]` — 稼働中コンテナ + `HOST/EXPOSE PORTS`、`NETWORKS`、`IP`、`PEER` を分離表示
- `dps -i [キーワード]` — `STATE` と `USED BY` 列付きの Docker イメージ一覧
- `dps -c <名前または#>` — 1つのコンテナの設定、ネットワーク、マウント、Compose 情報
- `dps -o` — `Images`、`Containers`、`Local Volumes`、`Build Cache` と孤立ボリュームの容量概要
- `dps -l <名前または#> [N]` — 末尾 `N` 行のログを表示（デフォルト 20）
- `dps -f <名前または#> [N]` — 末尾 `N` 行のログをリアルタイム追跡（デフォルト 20）
- `dps -h` — ヘルプを表示

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