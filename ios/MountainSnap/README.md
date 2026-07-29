# MountainSnap (iOS)

写真を撮った(または選んだ)山の名前・標高を表示し、近くにスキー場があれば合わせて表示するiOSアプリです。
`kanabun-git/ume` リポジトリ内の既存Rails製サイトとは完全に独立した、別プロジェクトです。

## 識別方式について(重要)

「写真の画像そのものから山を画像認識する」方式は、山ごとの大量の学習データが必要で
オンデバイスで精度よく実現するのは非常に困難です。そのため本アプリは
[PeakFinder](https://www.peakfinder.org/) など実在の山岳同定アプリと同じ方式を採用しています。

1. 撮影時(または写真のEXIF)から**現在地(GPS)**と**撮影方位(コンパス)**を取得する
2. 位置・方位から一定の視野角(既定60°)内に入る山を、内蔵の山岳データベースと照合する
3. カメラの向きに最も近い方位にある山を最有力候補として表示し、他の候補も列挙する
4. 一致した山(または現在地)の近くにあるスキー場をデータベースから検索して表示する

そのため、方位が正しく取得できないと正確な判定はできません。カメラで撮影する場合は
撮影直後に取得した位置・方位を使用し、フォトライブラリから選んだ写真はEXIFのGPS/方位情報
(あれば)を使用します。情報が無い場合は方角を手動で指定する画面が表示されます。

## 構成

```
MountainSnap/
  MountainSnap.xcodeproj/        Xcodeプロジェクト
  MountainSnap/
    MountainSnapApp.swift        アプリのエントリーポイント
    ContentView.swift            ホーム画面・撮影方向確認画面(状態遷移)
    Models/
      Mountain.swift             山データモデル
      SkiResort.swift            スキー場データモデル
    Services/
      GeoMath.swift              距離・方位角などの地理計算(CoreLocation非依存、テスト可能)
      MountainMatcher.swift      現在地・方位から山/スキー場を検索するロジック
      LocationHeadingProvider.swift  CoreLocationのGPS・コンパスのラッパー
      PhotoMetadataExtractor.swift   フォトライブラリ写真のEXIFからGPS/方位を抽出
      DataStore.swift            バンドルされたJSONデータの読み込み
    Views/
      CameraCaptureView.swift    UIImagePickerControllerのSwiftUIラッパー(撮影・ライブラリ選択共用)
      ResultView.swift           判定結果画面
    Resources/
      mountains_japan.json       山岳データ(主要な山、約30座)
      ski_resorts_japan.json     スキー場データ(主要スキー場、15件)
  MountainSnapTests/
    MountainMatcherTests.swift   距離・方位計算とマッチングロジックの単体テスト
```

## セットアップ

1. Xcode 15以降で `MountainSnap.xcodeproj` を開く
2. ターゲット「MountainSnap」の Signing & Capabilities で自分のApple Team を設定する
3. 実機を接続して実行する

**注意:** カメラとコンパスはシミュレーターでは利用できないため、動作確認には実機が必要です。

## 山岳・スキー場データについて

`Resources/mountains_japan.json` と `Resources/ski_resorts_japan.json` は、一般的な地理知識を基に
作成した**初期データ**です。緯度経度・標高は概算値を含むため、本番投入前に国土地理院(GSI)の
基準点情報など信頼できる情報源で検証・拡充してください。データ形式:

```json
// mountains_japan.json
{ "id": "fuji", "name": "富士山", "nameKana": "ふじさん", "elevationMeters": 3776,
  "latitude": 35.3606, "longitude": 138.7274, "prefecture": "静岡県・山梨県" }

// ski_resorts_japan.json
{ "id": "niseko_grandhirafu", "name": "ニセコグラン・ヒラフ",
  "latitude": 42.8637, "longitude": 140.6874, "nearestMountainId": "yotei",
  "baseElevationMeters": 210, "topElevationMeters": 1308 }
```

新しい山・スキー場を追加する場合は、それぞれのJSONに項目を追加するだけでよく、コード変更は不要です。

## 判定ロジックの調整

`MountainMatcher` (`Services/MountainMatcher.swift`) のプロパティで挙動を調整できます。

- `cameraHorizontalFieldOfViewDegrees`: カメラの水平画角(既定60°)
- `headingToleranceDegrees`: コンパス誤差の許容範囲(既定8°)
- `maxSearchRadiusMeters`: 検索する最大距離(既定200km)
- `minElevationForLongRangeMeters` / `longRangeThresholdMeters`: 遠距離では低い山を除外するための閾値

## 既知の制約

- 手前の稜線や建物で山が隠れている場合でも、視野角・距離条件を満たせば候補として表示されることがあります(遮蔽物の考慮はしていません)。
- 曇り・逆光などで実際には山が写っていない写真でも、位置・方位が条件を満たせば候補が表示されます(あくまで撮影地点・方向からの幾何学的な推定です)。
- コンパスの精度は端末の磁気較正状態に依存します。
- フォトライブラリの写真は、iPhoneの設定や撮影アプリによってはGPS/方位情報が記録されていないことがあります。その場合は手動で方角を指定してください。

## テスト

`MountainSnapTests/MountainMatcherTests.swift` に、距離・方位角計算とマッチングロジックの単体テストがあります。
このリポジトリの開発コンテナにはSwiftツールチェーンが無いため、テストの実行はXcode(またはmacOS上のCI)で行ってください。

```bash
xcodebuild test -project MountainSnap.xcodeproj -scheme MountainSnap -destination 'platform=iOS Simulator,name=iPhone 15'
```
