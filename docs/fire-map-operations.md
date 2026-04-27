# Fire Map 運用メモ

## 日次更新

1. NASA FIRMSのMAP_KEYをサーバーの環境変数に設定する。

```powershell
$env:FIRMS_MAP_KEY = "your-map-key"
```

2. サイトのルートで取得スクリプトを実行する。

```powershell
powershell -ExecutionPolicy Bypass -File scripts\download-firms-data.ps1
```

このスクリプトは最新10日分を取得し、`data/firms-otsuchi-latest.csv` を上書きします。HTMLはこの固定ファイル名を読むため、CSVを更新すればサイト表示も更新されます。`data/archive/` には実行日ごとの控えも保存します。

Windows Serverならタスクスケジューラで1日1回、Linux系サーバーならPowerShell 7または同等の取得処理をcronで実行してください。

## 公開前チェック

- `fire-map.html` にはFIRMS MAP_KEYを置かない。
- NASA APIはブラウザから直接呼ばず、サーバー側スクリプトでCSV化する。
- CSV由来の文字列はHTMLとして挿入しない。現在の実装は `textContent` / `replaceChildren` で描画する。
- 会社サーバー側でもCSP、`X-Content-Type-Options: nosniff`、HTTPSを設定する。OSM公式タイルを使う場合、`Referrer-Policy` は `strict-origin-when-cross-origin` などRefererを完全に消さない設定にする。
- CesiumJSはWebAssemblyとblob Workerを使うため、CSPでは `script-src` に `'wasm-unsafe-eval'` または環境によっては `'unsafe-eval'`、`blob:`、`worker-src blob:` を許可する。`frame-ancestors` はmetaタグではなくHTTPレスポンスヘッダーで設定する。
- 会社サーバーで `frame-ancestors` を使う場合はHTTPレスポンスヘッダーで設定する。クリックジャッキング対策として `frame-ancestors 'self'` または社内ドメインに限定する。
- 外部依存は `cesium.com`、`cyberjapandata.gsi.go.jp`、`api.open-meteo.com` です。これらを社内ポリシー上許容できない場合は、CesiumJSを自社配信し、風向データをサーバー側で取得・CSV/JSON化する構成に変更する。
- 現在の背景地図は国土地理院の写真タイルと標準地図タイルです。リアルタイムに読み込む利用は、出典明示のみで申請不要とされています。公開サーバーでは `cyberjapandata.gsi.go.jp` への通信が許可されているか確認する。
- 風向・風速はブラウザからOpen-Meteo JMA APIへ直接取得します。公開サーバーや社内ネットワークで `api.open-meteo.com` へのHTTPS通信を許可してください。取得に失敗した場合、画面は固定の参考値で表示を継続します。
- OSM公式タイルはSLAなしのコミュニティ基盤です。OSMへ戻す場合やアクセス増が見込まれる場合は、商用タイルプロバイダーか自社タイルサーバーを使う。
- Cesiumを外部CDNから読む運用が気になる場合は、社内サーバーに固定バージョンを配置して読み込む。

## 情報の扱い

NASA FIRMSは衛星の熱異常検知です。火災の公式な被害範囲、焼失面積、延焼予測ではありません。サイト内でもその前提が伝わる表現にしています。
