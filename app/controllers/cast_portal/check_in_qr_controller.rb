module CastPortal
  class CheckInQrController < BaseController
    before_action :set_cast

    def show
      @check_in_url = cast_check_in_url(@cast.checkin_token, host: request.base_url)
      qr_png = RQRCode::QRCode.new(@check_in_url).as_png(size: 320, border_modules: 1)
      @qr_data_url = "data:image/png;base64,#{Base64.strict_encode64(qr_png.to_s)}"
    end

    def pdf
      pdf = CastBusinessCardPdf.for_cast(@cast, base_url: request.base_url)
      send_data pdf, filename: "check_in_card_#{@cast.id}.pdf", type: "application/pdf", disposition: "inline"
    end

    private

    def set_cast
      @cast = current_cast_profile
      redirect_to cast_root_path, alert: "プロフィールが未登録です。店舗管理者にお問い合わせください。" if @cast.nil?
    end
  end
end
