# Ume Heaven

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

## iOSアプリ(MountainSnap)

本Railsアプリとは別に、`ios/MountainSnap` に山の名前・標高・近くのスキー場を判定するiOSアプリを
同梱しています。詳細は [ios/MountainSnap/README.md](ios/MountainSnap/README.md) を参照してください。
