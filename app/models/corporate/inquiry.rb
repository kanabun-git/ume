module Corporate
  # Form object backing the corporate site's contact form. Unlike
  # ShopInquiry, nothing here needs to persist or show up in an admin
  # screen -- the only consumer is CorporateInquiryMailer -- so this is a
  # plain ActiveModel object rather than an ActiveRecord one.
  class Inquiry
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :name, :string
    attribute :company_name, :string
    attribute :email, :string
    attribute :phone, :string
    attribute :message, :string
    # Honeypot: real visitors never see or fill this in (see
    # ShopInquiry's same pattern). Not validated against -- a filled-in
    # value is handled by the controller silently discarding the inquiry.
    attribute :website, :string

    validates :name, presence: true
    validates :email, presence: true
    validates :message, presence: true
  end
end
