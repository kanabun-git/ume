# FuzokuZero

Cityheavenのような風俗店ポータルサイト(店舗・在籍キャスト検索、口コミ、日記、ランキング)と、
3ロール(キャスト/店舗管理者/プラットフォーム運営者)の管理画面を備えたRailsアプリケーションです。

設計の詳細は [docs/architecture.md](docs/architecture.md)、ER図は
[docs/er_diagram.md](docs/er_diagram.md)、画面一覧は [docs/screens.md](docs/screens.md)、
権限マトリクスは [docs/permissions.md](docs/permissions.md) を参照してください。

## セットアップ

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

`db:seed` により以下のデモアカウントが作成されます(すべてパスワード `password1234`)。

| ロール | メールアドレス |
|---|---|
| プラットフォーム運営者 | admin@example.com |
| 店舗管理者 | shop_admin@example.com |
| キャスト | cast1@example.com |

## 必要環境

* Ruby 3.3
* PostgreSQL

## 主なロールとURL

| ロール | マイページURL |
|---|---|
| キャスト(女の子) | `/cast` |
| 店舗管理者 | `/shop_admin` |
| プラットフォーム運営者 | `/admin` |

## 運営会社(有限会社ピュアミント)コーポレートサイト

ポータル本体とは別に、運営会社そのものの紹介サイトを提供しています(会社概要・事業内容・アクセス・お問い合わせ)。本番で `PUREMINT_HOST` を設定すると、そのドメイン(`www.puremint.jp` を想定)の**トップページそのもの**として開けるようになります(`/`, `/company`, `/business`, `/access` など、接頭辞なしのURL)。開発・テストではホスト名の設定なしに `/corporate` 配下で確認できます(`CAST_PORTAL_HOST`/`MAIL_ADMIN_HOST` と同じ、ホストによる出し分けの仕組み)。

会社概要ページの郵便番号・建物名・電話番号は `app/models/corporate/company.rb` にプレースホルダーとして残っています。実データが揃い次第差し替えてください。

## 古着ブランド判定ツール(/vintage)

ポータル本体・コーポレートサイトとは独立した一般公開のツールです。古着のタグや洗濯表示の写真をアップロードすると、ブランド候補・推定年代・中古相場の目安と、その根拠をAI(Claude)が返します。

| URL | 内容 |
|---|---|
| `/vintage` | 判定フォーム(写真は最大4枚、写真が無くてもタグの表記メモだけで判定可) |
| `/vintage/guide` | 年代判定ガイド(共通の手がかりとブランド別のタグ変遷) |

* 本番では `VINTAGE_HOST` を設定すると、そのドメイン(`www.kanabun.tech` を想定)でしか開けなくなります(`CAST_PORTAL_HOST`/`MAIL_ADMIN_HOST`/`PUREMINT_HOST` と同じ、ホストによる出し分けの仕組み)。開発・テストではホスト名の設定なしにどのドメインからでも `/vintage` で確認できます。公開手順は [docs/vps_setup.md](docs/vps_setup.md) の「7-4」を参照してください。
* 判定には `ANTHROPIC_API_KEY` が必要です(写メ日記のAI下書きと同じ環境変数)。未設定でもフォームとガイドは開けますが、判定時にその旨のエラーを返します。
* アップロードされた写真は保存しません。そのリクエストの中でAPIへ渡すだけで、Active Storageにもディスクにも残しません(`app/models/vintage/identification.rb`)。
* AIの費用と待ち時間を抑えるため、IP単位で連続判定のクールダウンと時間あたりの上限を設けています(同ファイルの `COOLDOWN` / `WINDOW_LIMIT`)。
* 中古相場は「フリマアプリ・古着屋で売られている価格帯」で、買取価格ではありません。利用者が申告したコンディション・サイズを前提に見積もり、実売価格を自分で確認できるよう検索リンクも併記しています。
* 年代判定の知識は `app/models/vintage/brand_guide.rb` の定数にまとまっており、ガイドページの表示とAIへ渡す参考情報の**両方**がここを参照します。ブランドを追加・修正するときはこのファイルだけを直せば両方に反映されます。
