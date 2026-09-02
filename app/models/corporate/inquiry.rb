module Corporate
  # Form object backing the corporate site's contact form. Unlike
  # ShopInquiry, nothing here needs to persist or show up in an admin
  # screen -- the only consumer is CorporateInquiryMailer -- so this is a
  # plain ActiveModel object rather than an ActiveRecord one.
  class Inquiry
    include ActiveModel::Model
    include ActiveModel::Attributes

    # 事業内容ページの各サービスから来た問い合わせを一目で見分けられるよう、
    # 件名をプルダウンで選ばせる。新しい導線を増やす場合はここに追加し、
    # Corporate::Company::BUSINESS_LINESの該当項目にinquiry_subjectとして
    # 同じ文字列を指定する(Corporate::PagesController等を経由せず、
    # new_corporate_inquiry_path(subject: ...)のクエリparamでそのまま
    # プルダウンの初期選択に渡される)。
    SUBJECTS = ["やどかりペンションお問い合わせ", "その他"].freeze

    attribute :subject, :string
    attribute :name, :string
    attribute :company_name, :string
    attribute :email, :string
    attribute :phone, :string
    attribute :message, :string
    # Honeypot: real visitors never see or fill this in (see
    # ShopInquiry's same pattern). Not validated against -- a filled-in
    # value is handled by the controller silently discarding the inquiry.
    attribute :website, :string

    validates :subject, presence: true, inclusion: { in: SUBJECTS }
    validates :name, presence: true
    validates :email, presence: true
    validates :message, presence: true
  end
end
