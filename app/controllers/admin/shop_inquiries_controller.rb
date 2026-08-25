module Admin
  class ShopInquiriesController < BaseController
    before_action :set_shop_inquiry, only: [:show, :update_status, :archive, :unarchive, :destroy]

    def index
      authorize ::ShopInquiry, :index?
      @shop_inquiries = policy_scope(::ShopInquiry).active.page(params[:page]).per(20)
    end

    # Archived inquiries are kept out of #index (and its dashboard count) but
    # never deleted -- this lists them separately so the history stays
    # reachable.
    def archived
      authorize ::ShopInquiry, :index?
      @shop_inquiries = policy_scope(::ShopInquiry).archived.page(params[:page]).per(20)
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

    def archive
      @shop_inquiry.update!(archived_at: Time.current)
      redirect_to admin_shop_inquiries_path, notice: "お問い合わせをアーカイブしました。"
    end

    def unarchive
      @shop_inquiry.update!(archived_at: nil)
      redirect_to archived_admin_shop_inquiries_path, notice: "お問い合わせをアーカイブから戻しました。"
    end

    # Only archived inquiries can be permanently deleted -- an inquiry still
    # in the active list has to be archived first, so deletion always goes
    # through the same deliberate two-step (archive, then delete) the
    # confirmation dialog on the archived screen already implies.
    def destroy
      unless @shop_inquiry.archived?
        redirect_to admin_shop_inquiries_path, alert: "アーカイブ済みのお問い合わせのみ削除できます。"
        return
      end

      @shop_inquiry.destroy!
      redirect_to archived_admin_shop_inquiries_path, notice: "お問い合わせを完全に削除しました。"
    end

    private

    def set_shop_inquiry
      @shop_inquiry = ::ShopInquiry.find(params[:id])
      authorize @shop_inquiry
    end
  end
end
