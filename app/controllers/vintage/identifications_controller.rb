module Vintage
  class IdentificationsController < BaseController
    def new
      @identification = Vintage::Identification.new
    end

    def create
      @identification = Vintage::Identification.new(identification_params)
      @identification.ip_address = request.remote_ip

      unless @identification.valid?
        render :new, status: :unprocessable_entity and return
      end

      # `::`付き -- module Vintageの中で書くとVintage::VintageBrandIdentifier
      # として探されてしまうため(CastPortal側の同じ書き方と揃えている)。
      @result = ::VintageBrandIdentifier.new(identification: @identification).call
      # 判定できた場合だけ回数に数える。APIエラーで結果が返らなかった
      # リクエストで利用者の枠を消費させない。
      @identification.record_request!
      render :create
    rescue ::VintageBrandIdentifier::IdentificationError => e
      @identification.errors.add(:base, e.message)
      render :new, status: :service_unavailable
    end

    private

    def identification_params
      params.require(:vintage_identification).permit(:notes, :item_type, images: [])
    end
  end
end
