module Corporate
  class InquiriesController < BaseController
    def new
      @inquiry = Corporate::Inquiry.new
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
      params.require(:corporate_inquiry).permit(:name, :company_name, :email, :phone, :message, :website)
    end
  end
end
