# ER図

```mermaid
erDiagram
    USER {
        bigint id PK
        string email
        string encrypted_password
        string name
        integer role "cast=0, shop_admin=1, platform_admin=2"
        bigint shop_id FK "店舗管理者・キャストが所属する店舗(任意)"
    }

    AREA {
        bigint id PK
        string name
        string name_kana
        string slug UK "運営者が手動入力するURL用スラッグ"
        bigint parent_id FK "都道府県=NULL、市区町村は都道府県を指す"
        integer position
    }

    GENRE {
        bigint id PK
        string name
        string slug UK
        integer position
    }

    PLAN {
        bigint id PK
        string name
        integer monthly_fee
        integer priority_weight "ランキング倍率"
        integer position
    }

    SHOP {
        bigint id PK
        string name
        bigint area_id FK
        bigint genre_id FK
        bigint plan_id FK
        string catch_copy
        text description
        string address
        string phone
        string business_hours
        integer status "pending=0, approved=1, suspended=2"
        integer view_count
    }

    SHOP_SUBSCRIPTION {
        bigint id PK
        bigint shop_id FK
        bigint plan_id FK
        date started_on
        date ended_on
        integer status "active=0, canceled=1"
    }

    CAST {
        bigint id PK
        bigint shop_id FK
        bigint user_id FK "ログインアカウント(任意)"
        string name
        string alias_name
        integer age
        integer height
        integer bust
        integer waist
        integer hip
        string cup
        string catch_copy
        text description
        integer status "active=0, inactive=1"
    }

    DIARY_ENTRY {
        bigint id PK
        bigint cast_id FK
        string title
        text body
        integer status "draft=0, published=1"
        datetime published_at
    }

    SHIFT {
        bigint id PK
        bigint cast_id FK
        date work_date
        time start_time
        time end_time
        string note
        integer status "scheduled=0, cancelled=1"
    }

    REVIEW {
        bigint id PK
        bigint shop_id FK
        bigint cast_id FK "対象キャスト(任意)"
        string reviewer_name
        integer rating "1-5"
        text body
        integer status "pending=0, approved=1, rejected=2"
    }

    AREA ||--o{ AREA : "親子(都道府県-市区町村)"
    AREA ||--o{ SHOP : "所在エリア"
    GENRE ||--o{ SHOP : "業種"
    PLAN ||--o{ SHOP : "現在のプラン"
    PLAN ||--o{ SHOP_SUBSCRIPTION : ""
    SHOP ||--o{ SHOP_SUBSCRIPTION : "契約履歴"
    SHOP ||--o{ CAST : "在籍"
    SHOP ||--o{ REVIEW : ""
    SHOP ||--o{ USER : "所属(店舗管理者/キャスト)"
    CAST ||--o{ DIARY_ENTRY : ""
    CAST ||--o{ SHIFT : ""
    CAST ||--o{ REVIEW : "対象(任意)"
    CAST |o--o| USER : "ログインアカウント(任意・1対1)"
```

## 補足

- `Shop`(店舗)と`Cast`(在籍キャスト)は1対多。実際のCityheavenと同様、
  1店舗に複数の女性キャストが在籍する構成。
- `User`は3ロール共通の1テーブルで、`shop_admin`/`cast`ロールの場合のみ`shop_id`を持つ。
  `Cast`から`User`への`user_id`は「そのキャスト本人のログインアカウント」を指す(店舗管理者が
  発行するかどうかは任意 = ログインアカウントを持たないキャストも許容)。
- `Review`は`shop_id`必須・`cast_id`は任意(店舗全体への口コミ/特定キャストへの指名口コミの両対応)。
- ランキングは `Shop.view_count × Plan.priority_weight` の掛け算スコアで簡易的に算出する
  (`app/models/shop.rb` の `ranked` スコープ)。
