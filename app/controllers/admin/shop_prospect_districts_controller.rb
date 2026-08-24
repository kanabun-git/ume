module Admin
  # Districts are never created by hand here -- ShopProspect#sync_shop_prospect_district
  # registers them automatically from the CSV/manual genre field the first
  # time a district name is seen (defaulting prefecture to "東京", since
  # every listing imported so far only covers Tokyo). This screen only lets
  # an admin correct that guess once other prefectures start showing up.
  class ShopProspectDistrictsController < BaseController
    before_action :set_district, only: [:edit, :update]

    def index
      @districts = policy_scope(::ShopProspectDistrict).left_joins(:shop_prospects)
        .select("shop_prospect_districts.*, COUNT(shop_prospects.id) AS prospects_count")
        .group("shop_prospect_districts.id")
    end

    def edit
    end

    def update
      if @district.update(district_params)
        redirect_to admin_shop_prospect_districts_path, notice: "地区情報を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_district
      @district = ::ShopProspectDistrict.find(params[:id])
      authorize @district
    end

    def district_params
      params.require(:shop_prospect_district).permit(:name, :prefecture)
    end
  end
end
