module Corporate
  class InquiriesController < BaseController
    def new
      @inquiry = Corporate::Inquiry.new
      # 事業内容ページの「やどかりペンションの導入お問い合わせはこちら」等の
      # 導線から来た場合、?subject=... でプルダウンの初期選択を渡す(不正な
      # 値は無視して未選択のまま)。
      @inquiry.subject = params[:subject] if Corporate::Inquiry::SUBJECTS.include?(params[:subject])
    end

    def create
      @inquiry = Corporate::Inquiry.new(inquiry_params)

      # Honeypot: a field real visitors never see or fill in (see
      # ShopInquiriesController's same pattern). If it's filled, silently
      # pretend success rather than telling the bot it was caught.
      if @inquiry.website.present?
        render :create and return
      end

      if @inquiry.valid?
        CorporateInquiryMailer.notify_admin(@inquiry).deliver_now
        render :create
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def inquiry_params
      params.require(:corporate_inquiry).permit(:subject, :name, :company_name, :email, :phone, :message, :website)
    end
  end
end
