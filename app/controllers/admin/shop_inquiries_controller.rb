module Admin
  class ShopInquiriesController < BaseController
    before_action :set_shop_inquiry, only: [:show, :update_status]

    def index
      authorize ::ShopInquiry, :index?
      @shop_inquiries = policy_scope(::ShopInquiry).page(params[:page]).per(20)
    end

    def show
    end

    def update_status
      if ShopInquiry.statuses.key?(params[:status])
        @shop_inquiry.update!(status: params[:status])
        redirect_to admin_shop_inquiries_path, notice: "ステータスを更新しました。"
      else
        redirect_to admin_shop_inquiries_path, alert: "不正なステータスです。"
      end
    end

    private

    def set_shop_inquiry
      @shop_inquiry = ::ShopInquiry.find(params[:id])
      authorize @shop_inquiry
    end
  end
end
