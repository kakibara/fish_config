# fishセットアップ作業記録・再実行手順

## 今回確認した環境（2026-10-05）

- OS: macOS、CPU: arm64（Apple Silicon）。
- Homebrew: `/opt/homebrew/bin/brew`。
- fish: `/opt/homebrew/bin/fish`、バージョン4.9.3。
- peco: `/opt/homebrew/bin/peco`。
- 作業リポジトリ: `kakibara/fish_config`、ブランチ: `main`。

fishとpecoは既に導入されていました。今回の作業ではリポジトリを更新し、
実際の `~/.config/fish` へのセットアップやログインシェル変更は実行していません。

## 調査と更新内容

1. `git status --short` で既存の変更を確認し、スクリプト・README・設定を読みました。
2. `uname -m`、`command -v brew`、`command -v fish`、`fish --version`、
   `command -v peco` でこのPCの環境を確認しました。
3. fishとFisherの公式手順を確認しました。
4. Ubuntu専用のインストール処理を、macOSではHomebrew、Debian / Ubuntuではaptを使う処理へ更新しました。
   既存のコマンドは再インストールしません。インストール済みfishのアップグレードも自動では行いません。
5. リモートの設定ファイルをダウンロードする方式を、チェックアウト内の `files/` をコピーする方式に変更しました。
6. XDG_CONFIG_HOME対応、既存fish設定全体のバックアップ、ダウンロード失敗時の停止を追加しました。
7. Homebrewの環境設定とCtrl+Rの履歴検索を更新しました。検索キャンセル時は入力を保持します。
8. Bash・fishの構文、差分、モックを使ったバックアップ・再実行・ローカル設定の反映を確認しました。
9. 更新をコミット `939e98a` として `origin/main` にプッシュしました。
10. このドキュメントと、プラグインの管理用設定 `files/fish_plugins` を追加しました。
    プラグイン名は個別の引数として渡し、既存のほかのプラグインを削除しない方式です。

## このPCへ適用する

以下はBashまたはzshから実行します。既存のチェックアウトがある場合:

```sh
cd /Users/akiyuki/gits/fish_config
git pull --ff-only
bash setup_fish.sh
fish
```

新しいPCではREADMEのclone手順を使います。macOSではHomebrewを先に用意してください。
スクリプトは不足するfish / peco / curlをインストールし、指定プラグインを取得・更新します。
ネットワーク接続が必要です。apt経由のインストールではsudoが必要になる場合があります。

実行時に表示されるバックアップ先を記録してください。
設定先の `config.fish` と `functions/peco_select_history.fish` はリポジトリの内容で置き換わります。
独自設定がある場合は、バックアップと比較して必要な内容を戻してください。
プラグイン一覧は `files/fish_plugins` で管理し、変更後はセットアップを再実行します。
端末固有の履歴、`fish_variables`、認証情報、バックアップはリポジトリに追加しません。

## 適用後の確認

新しく起動したfish内で実行します。

```fish
fish --version
command -v brew
command -v peco
fisher list
functions -q z; and echo 'z: OK'
functions -q peco_select_history; and echo 'history function: OK'
bind \cr
```

コマンドをいくつか実行した後、Ctrl+Rで履歴検索が開くこと、選択した履歴が入力欄へ戻ること、
Escでキャンセルすると入力が保持されることを確認します。`z` で訪問済みディレクトリに移動できます。
agnosterの記号が崩れる場合は、ターミナルのフォントをPowerline対応フォントに変更します。
ログインシェルの変更はREADMEの手順で別途行います。

## 設定を復元する

fishを終了してBashまたはzshに戻り、実行時に表示されたバックアップを使います。
現在の設定も別名で保存してから復元します。

```sh
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
# 実行時に表示された実際のバックアップ先へ置き換える
backup_dir="${config_dir}.backup.XXXXXXXX"
test -d "$backup_dir" || exit 1
saved_dir="$(mktemp -d "${config_dir}.before-restore.XXXXXXXX")"
mv "$config_dir" "$saved_dir/fish"
cp -R "$backup_dir" "$config_dir"
```

新しいfishを起動して確認してください。パッケージのインストールはこの復元操作では取り消しません。

## リポジトリ更新時の検証とプッシュ

```sh
bash -n setup_fish.sh
fish --no-config --no-execute files/config.fish files/peco_select_history.fish
git diff --check
git diff
git add README.md docs/setup-guide.md setup_fish.sh files/
git commit -m "Document fish setup and manage plugin configuration"
git push origin main
```

構文チェックとモック検証は、実機でのプラグインダウンロードや対話操作の確認とは別です。
今回の初回更新では実際のセットアップは実行せず、モックでmacOS分岐・XDG設定先・
全体バックアップ・2回の再実行・既存パッケージの保持を検証しました。

参照: [fish公式](https://github.com/fish-shell/fish-shell)、
[Fisher公式](https://github.com/jorgebucaran/fisher)。
