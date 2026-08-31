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

ポータル本体とは別に、運営会社そのものの紹介サイトを `/corporate` 配下で提供しています(会社概要・事業内容・アクセス・お問い合わせ)。本番で `PUREMINT_HOST` を設定すると、そのドメイン(`www.puremint.jp` を想定)でしか開けなくなります(`CAST_PORTAL_HOST`/`MAIL_ADMIN_HOST` と同じ仕組み)。開発・テストではホスト名の設定なしにそのまま `/corporate` で確認できます。

会社概要ページの住所・代表者名・資本金などは `app/models/corporate/company.rb` にプレースホルダーとして定義しています。公開前に実際の登記情報へ差し替えてください。
