module Admin
  class ShopInquiriesController < BaseController
    before_action :set_shop_inquiry, only: [:show, :update_status, :archive, :unarchive, :destroy, :reply]

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
      @reply_body = @shop_inquiry.reply_body.presence || ::ShopInquiryReplyTemplate.instance.body
    end

    def update_status
      if ShopInquiry.statuses.key?(params[:status])
        @shop_inquiry.update!(status: params[:status])
        redirect_to admin_shop_inquiries_path, notice: "ステータスを更新しました。"
      else
        redirect_to admin_shop_inquiries_path, alert: "不正なステータスです。"
      end
    end

    # Sends the shop an actual email (see ShopInquiryMailer#reply_to_inquirer)
    # -- unlike a review's shop_reply, an inquiry is never shown anywhere
    # public, so email is the only way to get a reply back to them.
    def reply
      body = params[:reply_body].to_s.strip
      if body.blank?
        redirect_to admin_shop_inquiry_path(@shop_inquiry), alert: "返信内容を入力してください。"
        return
      end

      @shop_inquiry.reply_body = body
      @shop_inquiry.replied_at = Time.current
      ShopInquiryMailer.reply_to_inquirer(@shop_inquiry).deliver_now
      @shop_inquiry.save!

      redirect_to admin_shop_inquiry_path(@shop_inquiry), notice: "返信メールを送信しました。"
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
