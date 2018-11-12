# TodoAndNote

## Description

Dropbox でファイル共有出来るiOS用のMarkdownエディター

- task lists (checkbox) が書けるので TODO管理としても使えます
- Markdownのパース・表示は [Marked.js](https://github.com/markedjs/marked) を使っています
- Dropboxの `Notes/`  フォルダー下のファイルのみ扱います、また Notes/ フォルダーの直下にフォルダーを作れます(ただし、フォルダーの作成・管理機能はありません)
- MarkdowファイルにTag(カラーバー)を追加出来ます。この管理情報は `.attributes.json` ファイルに書かれています
- Markdowのバックアップ機能は `zBackup/` フォルダに日付付きファイルのコピーを作ります

![TodoAndNote](https://www.ey-office.com/images/TodoAndNote.png)

## Build

Dropbox とのインタフェースは [Dropbox Swift SDK](https://www.dropbox.com/developers/documentation/swift) ライブラリーを使っています。Dropbox Swift SDK  のインストールには Carthageを使っています、インストール手順は [Dropbox Swift SDK ](https://github.com/dropbox/SwiftyDropbox#carthage) を参照して下さい。

また、[Build your app on the DBX Platform の Create your app](https://www.dropbox.com/developers/apps/create) で新規アプリを登録し App key を取得し TodoAndNote/Info.plist に登録する必要があります

~~~xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>

  ... 略 ...

        <array>
                <dict>
                        <key>CFBundleURLSchemes</key>
                        <array>
                                <string>db-＊ここにApp keyを設定＊</string>
                        </array>
                        <key>CFBundleURLName</key>
                        <string></string>
                </dict>
        </array>
</dict>
</plist>

~~~





## License

[MIT License](http://www.opensource.org/licenses/MIT).