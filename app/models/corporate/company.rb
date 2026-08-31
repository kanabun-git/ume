module Corporate
  # Static 会社概要 facts for the corporate site (puremint.jp). Plain
  # constants rather than a SiteSetting-style DB row -- this data changes
  # about as often as the company's own registration does, so a deploy is
  # an acceptable way to update it.
  #
  # NOTE: POSTAL_CODE / BUILDING / PHONE are still placeholders pending the
  # real company register info -- swap them in before this site goes live.
  class Company
    NAME = "有限会社ピュアミント"
    NAME_EN = "PureMint Co., Ltd."
    POSTAL_CODE = "000-0000(ご記入ください)"
    ADDRESS = "東京都西東京市田無町2-20-3"
    BUILDING = nil
    REPRESENTATIVE = "福島 保彦"
    ESTABLISHED_ON = "2005年6月1日"
    CAPITAL = "300万円"
    PHONE = "00-0000-0000(ご記入ください)"
    EMAIL = "info@puremint.jp"

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
      }
    ].freeze
  end
end
