module Corporate
  # Static 会社概要 facts for the corporate site (puremint.jp). Plain
  # constants rather than a SiteSetting-style DB row -- this data changes
  # about as often as the company's own registration does, so a deploy is
  # an acceptable way to update it.
  #
  class Company
    NAME = "有限会社ピュアミント"
    NAME_EN = "PureMint Co., Ltd."
    POSTAL_CODE = "188-0011"
    ADDRESS = "東京都西東京市田無町2-20-3"
    BUILDING = nil
    REPRESENTATIVE = "福島 保彦"
    ESTABLISHED_ON = "2005年6月1日"
    CAPITAL = "300万円"
    EMAIL = "info@puremint.jp"

    # 古着ブランド判定ツールの公開URL。VINTAGE_HOSTを設定した本番では
    # そのドメイン(www.kanabun.tech想定)の絶対URL -- コーポレートサイトは
    # 別ドメイン(puremint.jp)で動くため、"/vintage" の相対パスでは開けない。
    # 未設定の開発・テストでは同じアプリの中にあるので相対パスでよい。
    VINTAGE_TOOL_URL =
      ENV["VINTAGE_HOST"].present? ? "https://#{ENV["VINTAGE_HOST"]}/vintage" : "/vintage"

    BUSINESS_LINES = [
      {
        title: "インターネットポータルサイトの企画・開発・運営",
        body: "エリア・ジャンルから店舗やキャストを探せる検索サイトの企画立案から、" \
          "システム開発、公開後の運営・保守までを一貫して手がけています。"
      },
      {
        title: "インターネット広告事業",
        body: "運営するポータルサイト上でのクーポン配信・プレゼント企画・掲載店舗向け" \
          "広告枠の提供など、Web集客に関する広告サービスを提供しています。"
      },
      {
        title: "メールシステムの管理・運用",
        body: "自社および提携先が利用するメールドメイン・メールアカウントの管理、" \
          "送受信環境の保守運用を行っています。"
      },
      {
        title: "やどかりペンションHP",
        body: "全国のペンション・宿泊施設のオーナー様向けに、写真ギャラリーや料金表、" \
          "お知らせなどをご自身で簡単にカスタマイズできるホームページサービス" \
          "「やどかりペンションHP」を提供しています。",
        features: [
          "予約管理機能(メールやLINEでお知らせ)",
          "宿泊履歴管理(当日や過去の宿泊者の履歴確認可能)",
          "HP作成の知識がなくても簡単に見た目の変更や情報が変えられる管理画面を搭載"
        ],
        url: "https://www.kanabun.tech/pension_basic/",
        link_label: "やどかりペンションHPを見る",
        inquiry_subject: "やどかりペンションお問い合わせ",
        inquiry_link_label: "やどかりペンションの導入お問い合わせはこちら"
      },
      {
        title: "古着ブランド判定ツール",
        body: "古着のタグを撮影するだけで、ブランド候補・製造年代・中古相場の目安を" \
          "AIが推定する無料のWebツールを公開しています。ブランド名が擦れて読めない" \
          "アイテムや、年代と値段の見当を付けたいときにお使いいただけます。",
        features: [
          "タグ・洗濯表示・縫製の写真から、ブランド候補と推定年代を提示",
          "コンディションとサイズを踏まえた中古相場(販売価格帯)の目安を表示",
          "ブランド別のタグ変遷をまとめた年代判定ガイドを併設"
        ],
        # ルート定義側(config/routes.rbのvintage namespace)と対になっている。
        # パスやホストを動かすときは上のVINTAGE_TOOL_URLも直すこと
        # (この定数からはURLヘルパーを呼べないため、URLをそのまま持っている)。
        url: VINTAGE_TOOL_URL,
        link_label: "古着ブランド判定ツールを使う"
      }
    ].freeze
  end
end
