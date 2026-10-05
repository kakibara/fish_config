# fish_config

fish、peco、Fisher、z、agnosterをセットアップします。
macOS（Apple Silicon / Intel、Homebrew必須）とDebian / Ubuntu（apt）に対応しています。
既にあるfish / pecoは再インストールしません。Linuxではディストリビューション提供版を使用します。

## セットアップ

```sh
git clone https://github.com/kakibara/fish_config.git
cd fish_config
bash setup_fish.sh
fish
```

既にチェックアウトしている場合は、そのディレクトリで `bash setup_fish.sh` を実行します。
設定ファイルはローカルの `files/` からコピーするため、未公開の変更も反映されます。
`curl ... | sh` による実行には対応していません。

設定先は `${XDG_CONFIG_HOME:-$HOME/.config}/fish` です。
既存の設定ディレクトリ全体を隣接する `fish.backup.XXXXXXXX` に保存してから、
`config.fish`、履歴検索関数、プラグインを更新します。
再実行すると指定プラグインも更新されます。既存のほかのプラグインは削除しません。

Ctrl+Rでpecoの履歴検索を開きます。入力中の文字列が検索に使われ、キャンセルすると入力を保持します。
agnosterの記号表示にはPowerline対応フォントをターミナルに設定してください。

## ログインシェルをfishに変更する場合

まず `fish` で動作確認した後、次を実行してください（パスワード入力が必要になる場合があります）。

```sh
command -v fish
# 上で表示されたパスが /etc/shells に未登録の場合だけ追加する
command -v fish | sudo tee -a /etc/shells
chsh -s "$(command -v fish)"
```

新しいターミナルを開くと反映されます。macOSで元に戻す場合は `chsh -s /bin/zsh` を実行します。
スクリプト自体はログインシェルを変更しません。

参照: [fishの公式インストール手順](https://github.com/fish-shell/fish-shell)、
[Fisher](https://github.com/jorgebucaran/fisher)。
