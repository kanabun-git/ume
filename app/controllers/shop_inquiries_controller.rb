class ShopInquiriesController < ApplicationController
  def new
    @shop_inquiry = ShopInquiry.new
    authorize @shop_inquiry
  end

  def create
    # Honeypot: a field real visitors never see or fill in (see reviews'
    # same pattern in ReviewsController#create). If it's filled, silently
    # pretend success rather than telling the bot it was caught.
    if params.dig(:shop_inquiry, :website).present?
      redirect_to root_path, notice: "お問い合わせを受け付けました。担当者よりご連絡いたします。" and return
    end

    @shop_inquiry = ShopInquiry.new(shop_inquiry_params)
    authorize @shop_inquiry

    if @shop_inquiry.save
      ShopInquiryMailer.notify_admin(@shop_inquiry).deliver_now
      redirect_to root_path, notice: "お問い合わせを受け付けました。担当者よりご連絡いたします。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def shop_inquiry_params
    params.require(:shop_inquiry).permit(:shop_name, :contact_name, :email, :phone, :area_note, :message)
  end
end
