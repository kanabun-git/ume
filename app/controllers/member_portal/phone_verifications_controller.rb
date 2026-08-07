module MemberPortal
  class PhoneVerificationsController < BaseController
    def new
      session[:phone_verification_return_to] = safe_return_to(params[:return_to])
    end

    # Issues a verification code for the given phone number. This
    # environment has no real SMS gateway on file, so the code is shown
    # directly on screen instead of actually being texted -- swap this for
    # a real SMS API call (Twilio, etc.) before going to production.
    def create
      phone_number = params[:phone_number].to_s.strip
      if phone_number.blank?
        redirect_to new_member_phone_verification_path, alert: "電話番号を入力してください。"
        return
      end

      @code = PhoneVerificationCode.issue!(member: current_member, phone_number: phone_number)
      flash[:notice] = "(開発用)認証コード #{@code.code} をSMSで送信しました。実際のSMS送信は行われません。"
      redirect_to edit_member_phone_verification_path
    end

    def edit
    end

    def update
      active_code = current_member.phone_verification_codes.active.order(created_at: :desc).first

      if active_code.blank?
        redirect_to new_member_phone_verification_path, alert: "認証コードの有効期限が切れました。もう一度送信してください。"
        return
      end

      if active_code.code == params[:code].to_s.strip
        active_code.update!(consumed_at: Time.current)
        current_member.update!(phone_number: active_code.phone_number, phone_verified_at: Time.current)
        redirect_to(session.delete(:phone_verification_return_to) || member_root_path, notice: "SMS認証が完了しました。")
      else
        redirect_to edit_member_phone_verification_path, alert: "認証コードが正しくありません。"
      end
    end

    private

    # Only ever redirect back into this app's own paths -- a raw external
    # return_to param would otherwise turn this into an open redirect.
    def safe_return_to(path)
      return nil if path.blank? || !path.start_with?("/") || path.start_with?("//")

      path
    end
  end
end
