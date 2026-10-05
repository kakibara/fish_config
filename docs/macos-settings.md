# Macintosh HDからmacOS設定を移行する

## コピー元と収録内容

2026-10-05に、起動中のSSDとは別の `Macintosh HD - Data` にある
`/Volumes/Macintosh HD - Data/Users/akiyuki/Library/Preferences` から読み取りました。
`Macintosh HD/Users` 側にもユーザーフォルダが見えますが、収録時はData側を使用しています。
元ディスクや現在のMacの設定は変更していません。

設定ファイルは `files/macos/settings.json`、読み取り・適用ツールは `macos_settings.py` です。
ユーザー名やディスクの識別情報を設定ファイルに保存せず、選定したキーだけを収録しています。

確認できた主な値:

| 項目 | Macintosh HDの保存値 |
| --- | --- |
| ナチュラルなスクロール | オフ |
| 外観 | ダーク |
| Dockの自動非表示 | オン |
| Dockサイズ | 68 |
| Finderのパスバー | 表示 |
| Finderの既定表示 | リスト（Nlsv） |
| 外付けディスク・リムーバブルメディアをデスクトップに表示 | オン |
| 内蔵ディスクをデスクトップに表示 | オフ |
| トラックパッドのタップでクリック | オフ |
| トラックパッドの副ボタン・ピンチ・回転 | オン |
| トラックパッドの3本指ドラッグ | オフ |

`null` は元のplistにキーが保存されていない項目です。実際の有効値を推測せず、適用時はスキップします。
速度・キーリピートなど、未保存の項目は移行先のシステム設定で確認してください。
収録するキーはツール内の `KEYS` に列挙しています。
Dockのアプリ配列、最近使ったフォルダ、スクリーンショット保存先、アカウント、ネットワーク、
Bluetoothペアリング、端末固有のByHost設定、アプリ固有のマウス設定は移行しません。

## 移行先で適用する

macOSとPython 3が必要です。`python3 --version` で確認してください。
fishセットアップとは独立した操作で、sudoは不要です。システム設定アプリを閉じてから実行します。

```sh
cd /Users/akiyuki/gits/fish_config
# 適用予定のコマンドだけを確認（設定変更なし）
python3 macos_settings.py apply --dry-run
# 確認した内容を適用
python3 macos_settings.py apply
```

適用前に変更対象キーの元の値を
`~/Library/Application Support/fish_config/macos-backups/` にJSONで保存します。
エラーで途中停止した場合も、このバックアップから戻せます。
適用後は作業を保存してログアウト・ログインし、各設定を確認してください。
プロセスの強制終了や自動ログアウトは行いません。

`defaults` のキーはmacOSのバージョンや接続機器によって反映されない場合があります。
とくにトラックパッド／Magic Mouse用のキーは機器が異なると同じ動作にならないことがあります。
GUI上の値と実際の操作を最終確認してください。

## スクロール方向を確認する

1. システム設定 → マウス →「ナチュラルなスクロール」がオフになっていることを確認します。
2. トラックパッドがある場合は、システム設定 → トラックパッド → スクロールとズームでも確認します。
3. ブラウザなどで実際にスクロールして元のMacと同じ方向か確認します。
4. マウス用ユーティリティを使っている場合は、そのアプリ側の反転設定も確認します。

Appleの説明ではナチュラルなスクロールは指と同じ方向へ内容を移動する設定です。
参照: [Appleのマウス設定](https://support.apple.com/en-my/guide/mac-help/mh29222/mac)。

Dockの自動非表示、Finderのパスバー・リスト表示、ダークモードも確認してください。

## バックアップから戻す

適用時に表示された実際のバックアップファイル名を指定します。

```sh
python3 macos_settings.py restore --file "$HOME/Library/Application Support/fish_config/macos-backups/実際のファイル名.json" --dry-run
python3 macos_settings.py restore --file "$HOME/Library/Application Support/fish_config/macos-backups/実際のファイル名.json"
```

復元では、以前未保存だったキーは削除して元の未設定状態へ戻します。
復元前の値も別のバックアップに保存します。その後ログアウト・ログインして確認します。

## 後日、設定を取り直す

元ディスクから新しいファイルへ書き出す例:

```sh
python3 macos_settings.py export \
  --source-preferences "/Volumes/Macintosh HD - Data/Users/akiyuki/Library/Preferences" \
  --file /tmp/macos-settings-new.json
```

起動中のMacから取得する場合は `--source-preferences` を省略します。
既存ファイルを誤って上書きしないため、出力先は新しいファイル名にしてください。
差分を確認してから `files/macos/settings.json` に反映します。
バックアップはGitに追加しないでください。
