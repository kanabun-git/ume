# The editable default wording pre-filled into 掲載のお問い合わせ's reply
# textarea (see Admin::ShopInquiriesController#show / 定型文の編集). Like
# SiteSetting/OutreachEmailTemplate, this table only ever holds a single
# row -- callers ask for "the" template via .instance.
class ShopInquiryReplyTemplate < ApplicationRecord
  DEFAULT_BODY = <<~BODY.freeze
    この度は「風俗Zero」への掲載についてお問い合わせいただき、誠にありがとうございます。

    担当者より改めてご連絡させていただきますので、今しばらくお待ちくださいませ。
  BODY

  validates :body, presence: true

  def self.instance
    first_or_create! do |t|
      t.body = DEFAULT_BODY
    end
  end
end
