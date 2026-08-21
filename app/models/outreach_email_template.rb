# The editable wording for ShopProspectMailer#outreach_email (see 営業先候補管理
# > 営業メール文面の編集). Like SiteSetting, this table only ever holds a single
# row -- callers ask for "the" template via .instance.
class OutreachEmailTemplate < ApplicationRecord
  PLACEHOLDER_PATTERN = /%\{(\w+)\}/

  DEFAULT_SUBJECT = "【FuzokuZero】掲載のご案内".freeze
  DEFAULT_BODY = <<~BODY.freeze
    %{name} 様

    突然のご連絡失礼いたします。風俗ポータルサイト「FuzokuZero」運営事務局です。

    貴店の掲載を拝見し、ぜひ弊社サイトへの掲載もご案内したく、ご連絡いたしました。

    FuzokuZeroでは、以下のような機能を無料でご利用いただけます。

    ・体験動画の撮影・編集・アップロードまで弊社スタッフが代行
    ・プレゼント企画による会員の集客・リピート促進
    ・店舗ごとに自由にカスタマイズできるサイトレイアウト

    掲載にご興味をお持ちいただけましたら、以下のリンクよりお気軽にお問い合わせください。

    %{registration_url}

    ご不明な点がございましたら、上記フォームよりお気軽にご連絡ください。
  BODY

  validates :subject, presence: true
  validates :body, presence: true
  validate :body_includes_registration_url_placeholder

  def self.instance
    first_or_create! do |t|
      t.subject = DEFAULT_SUBJECT
      t.body = DEFAULT_BODY
    end
  end

  def render_subject(vars)
    render(subject, vars)
  end

  def render_body(vars)
    render(body, vars)
  end

  private

  # Only substitutes recognized %{word} placeholders (unknown ones become a
  # blank string); a stray literal "%" the admin types is left untouched.
  # Deliberately not String#%, which raises on any placeholder that isn't in
  # the hash -- a typo in a free-text field shouldn't crash mail delivery.
  def render(text, vars)
    text.gsub(PLACEHOLDER_PATTERN) { vars[$1.to_sym].to_s }
  end

  def body_includes_registration_url_placeholder
    return if body.to_s.include?("%{registration_url}")

    errors.add(:body, "には %{registration_url} のプレースホルダーを含めてください(登録案内リンクの差し込み位置)")
  end
end
