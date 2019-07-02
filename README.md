# TodoAndNote

## Description

GoogleDrive でファイル共有出来るiOS用のMarkdownエディター

- task lists (checkbox) が書けるので TODO管理としても使えます
- Markdownのパース・表示は [Marked.js](https://github.com/markedjs/marked) を使っています
- GoogleDriveの `Notes/`  フォルダー下のファイルのみ扱います、また Notes/ フォルダーの直下にフォルダーを作れます(ただし、フォルダーの作成・管理機能はありません)
- MarkdowファイルにTag(カラーバー)を追加出来ます。この管理情報は `.attributes.json` ファイルに書かれています
- Markdowのバックアップ機能は `zBackup/` フォルダに日付付きファイルのコピーを作ります

![TodoAndNote](https://www.ey-office.com/images/TodoAndNote.png)

## Build

* Podのインストール

```
$ pod install
```

* Google Drive APIの OAuth 2.0 クライアントIDを設定

[Google Developer Console](https://console.developers.google.com/?hl=JA)で *OAuth 2.0 クライアント ID* の *認証情報を作成* し、クライアント ID(ドメイン名)を逆順にし、 *Info.plist* の *CFBundleURLSchemes* に書き込む

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
                                <string>＊ここにクライアントIDの逆ドメイン名を設定＊</string>
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