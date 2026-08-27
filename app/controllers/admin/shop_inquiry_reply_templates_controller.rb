module Admin
  # Lets a platform admin freely rewrite the default reply text pre-filled
  # on 掲載のお問い合わせ's reply form (see Admin::ShopInquiriesController#show)
  # without a deploy. No Pundit policy here -- like Admin::SettingsController,
  # Admin::BaseController's require_platform_admin_role! already gates the
  # whole namespace.
  class ShopInquiryReplyTemplatesController < BaseController
    def edit
      @shop_inquiry_reply_template = ::ShopInquiryReplyTemplate.instance
    end

    def update
      @shop_inquiry_reply_template = ::ShopInquiryReplyTemplate.instance

      if @shop_inquiry_reply_template.update(template_params)
        redirect_to edit_admin_shop_inquiry_reply_template_path, notice: "返信の定型文を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def template_params
      params.require(:shop_inquiry_reply_template).permit(:body)
    end
  end
end
