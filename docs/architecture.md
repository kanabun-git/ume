# アーキテクチャ概要

Cityheavenのような「風俗店ポータルサイト」(店舗・在籍キャスト検索、口コミ、日記、ランキング)を、
Ruby on Rails 7.2 のモノリシックアプリケーションとして設計・実装した。

## 技術スタック

| レイヤ | 技術 |
|---|---|
| 言語/フレームワーク | Ruby 3.3 / Rails 7.2 |
| DB | PostgreSQL |
| 認証 | Devise (単一 `User` モデル + `role` enum) |
| 認可 | Pundit (ロール別 Policy クラス) |
| ファイルアップロード | Active Storage (店舗写真・キャスト写真・日記写真) |
| ページネーション | Kaminari |
| フロントエンド | Rails標準ERB + Turbo/Stimulus (importmap)、素のCSS |

外部SaaS化・API分割は行わず、まずは単一Railsアプリで全ロールの画面を提供する構成とした
(公開サイト・キャストマイページ・店舗管理画面・運営管理画面の4つの画面群を同一アプリ内の
名前空間で分離)。

## ロールモデル

このサービスには3種類のログインロールが存在する。単一の `User` テーブルに `role` enum
(`cast` / `shop_admin` / `platform_admin`) を持たせ、Deviseで認証したうえでPunditの
Policyクラスでロールごとのアクセス制御を行う。

| ロール | 説明 | ログイン後の画面 |
|---|---|---|
| キャスト(女の子) | 店舗に在籍する女性キャスト本人 | `/cast` 配下(自分のプロフィール・日記・出勤予定のみ編集可) |
| 店舗管理者 | 店舗のオーナー/スタッフ | `/shop_admin` 配下(自店舗の情報・在籍キャスト・写真・日記閲覧・口コミ閲覧) |
| プラットフォーム運営者 | サイト運営会社のスタッフ | `/admin` 配下(全店舗審査・エリア/ジャンル/プラン管理・口コミモデレーション・全ユーザー管理) |

一般利用者(サイト訪問者)はログイン不要で店舗検索・キャスト閲覧・口コミ投稿ができる
(投稿された口コミは運営者の承認後に公開される、というモデレーションフローを採用)。

### なぜ単一Userテーブルなのか

キャスト・店舗管理者・運営者は同じ認証機構(メール+パスワード)を使い、相互に兼任することは
ないため、テーブルを分けるより`role`カラムで分岐する方がシンプルで、Deviseの設定も1つで済む。
将来的に「1人が複数店舗を管理する」等の要件が出た場合は、User-Shopの中間テーブル化を検討する。

## 名前空間設計 (コントローラ)

Railsのルーティング `namespace :cast` は暗黙的に `module Cast` を生成しようとするが、
ドメインモデルの `Cast`(在籍キャスト)クラスと衝突するため、
`namespace :cast, module: "cast_portal"` としてURL/ルーティングヘルパー名は `/cast` 配下・
`cast_xxx_path` のまま維持しつつ、コントローラの実体は `CastPortal::` 名前空間に置いている
(`app/controllers/cast_portal/`, `app/views/cast_portal/`)。

## ディレクトリ構成(抜粋)

```
app/
  controllers/
    home_controller.rb          # 公開: トップページ
    areas_controller.rb         # 公開: エリア別店舗一覧
    genres_controller.rb        # 公開: ジャンル別店舗一覧
    shops_controller.rb         # 公開: 店舗一覧・詳細
    casts_controller.rb         # 公開: キャスト詳細
    rankings_controller.rb      # 公開: ランキング
    reviews_controller.rb       # 公開: 口コミ投稿(非会員可)
    cast_portal/                # キャスト(女の子)マイページ
      dashboard_controller.rb
      profiles_controller.rb    # プロフィール編集(自分の部分のみ)
      diary_entries_controller.rb
      shifts_controller.rb
    shop_admin/                 # 店舗管理者
      dashboard_controller.rb
      shops_controller.rb       # 自店舗の内容編集(ステータス/プラン等は不可)
      casts_controller.rb       # 在籍キャストCRUD(ログインアカウント発行含む)
      diary_entries_controller.rb # 閲覧のみ
      reviews_controller.rb     # 閲覧のみ
    admin/                      # プラットフォーム運営者
      dashboard_controller.rb
      shops_controller.rb       # 店舗CRUD・承認/停止
      areas_controller.rb
      genres_controller.rb
      plans_controller.rb
      shop_subscriptions_controller.rb
      reviews_controller.rb     # 口コミ承認/却下/削除
      users_controller.rb       # 全ユーザー管理
  models/
    user.rb, shop.rb, cast.rb, diary_entry.rb, shift.rb, review.rb,
    area.rb, genre.rb, plan.rb, shop_subscription.rb
  policies/
    application_policy.rb, platform_admin_policy.rb(基底),
    shop_policy.rb, cast_policy.rb, diary_entry_policy.rb, shift_policy.rb,
    review_policy.rb, user_policy.rb, area_policy.rb, genre_policy.rb,
    plan_policy.rb, shop_subscription_policy.rb
```

## 権限制御の実装方針

- 認証は `before_action :authenticate_user!`、ロールチェックは各名前空間の
  `BaseController#require_xxx_role!` で行い、URLレベルで完全に画面を分離する。
- 個別レコードへのアクセス制御(自店舗のデータしか触れない等)はPunditの
  `Policy#update?` 等と `policy_scope` で行う。二重チェックにはなるが、
  「他人の店舗のURLを直接叩かれても弾く」ための最終防衛ラインとして機能する。
- キャストは自分のプロフィールの一部フィールド(キャッチコピー・自己紹介・写真・体型情報)のみ
  編集可能で、氏名・年齢・在籍店舗・在籍ステータスは店舗管理者のみが変更できる
  (`Cast::update_profile?` と `Cast::update?` を分離)。
- 口コミは匿名投稿可能だが、承認(`approved`)されるまで公開ページに表示されない。
  承認・却下は運営者のみ (`ReviewPolicy#moderate?`)。

## ランキング/プラン制度

Cityheavenと同様、店舗は月額プラン(`Plan`: フリー/スタンダード/プレミアム)に加入することで
`priority_weight` が上がり、ランキング表示順(`Shop.ranked`)で有利になる設計とした。
契約状態は `ShopSubscription` で管理し、運営者が付与・変更する。

```ruby
scope :ranked, -> { visible.joins(:plan).order(Arel.sql("plans.priority_weight * shops.view_count DESC")) }
```

これはMVPとしての単純化であり、実運用では「閲覧数の不正水増し対策」「日次/週次スコア減衰」
「表示順の恣意性の監査」などを追加検討する必要がある。

## 既知の簡略化・今後の課題

- **出勤予定(Shift)は日付またぎに対応していない**: `time`型カラム(日付を持たない)で
  `start_time`/`end_time`を管理しているため、深夜0時をまたぐ勤務(例: 18:00-26:00)を
  そのまま表現できない。実運用では終了時刻をdatetime化する、または「日付+分の経過」で
  持たせる設計に変更が必要。
- **エリア/ジャンルのスラッグは手動入力**: 日本語名をFriendlyId等で自動スラッグ化すると、
  ローマ字変換テーブルがないため意味のあるURLにならず(UUIDにフォールバックする)、
  運営者が管理画面から半角英数字のスラッグを直接入力する方式にした。
  店舗・キャストのURLは数値IDベース(実際のCityheavenと同様の方式)。
- **決済機能は未実装**: プラン契約(`ShopSubscription`)はデータモデルのみで、実際の
  請求・カード決済連携(Stripe等)は含まれていない。
- **画像バリアント(リサイズ)は未使用**: `image_processing`は導入済みだが、
  現状は元画像をそのまま表示している。本番では`variant(resize_to_limit: ...)`等で
  配信サイズを最適化する。
- **メール送信は未設定**: パスワードリセット等のDevise機能はモデルに含まれるが、
  ActionMailerの実送信設定(SMTP等)は未構成。
