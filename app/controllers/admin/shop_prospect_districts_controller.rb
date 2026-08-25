module Admin
  # Districts are never created by hand here -- ShopProspect#sync_shop_prospect_district
  # registers them automatically from the CSV/manual genre field the first
  # time a district name is seen (defaulting prefecture to "東京", since
  # every listing imported so far only covers Tokyo). This screen only lets
  # an admin correct that guess once other prefectures start showing up.
  class ShopProspectDistrictsController < BaseController
    before_action :set_district, only: [:edit, :update, :register_area]

    def index
      @districts = policy_scope(::ShopProspectDistrict).left_joins(:shop_prospects)
        .select("shop_prospect_districts.*, COUNT(shop_prospects.id) AS prospects_count")
        .group("shop_prospect_districts.id")

      # Lets an admin add a district to the site's own Area taxonomy
      # straight from here when it's missing there (see #register_area) --
      # ShopProspectDistrict and Area are deliberately separate tables (one
      # tracks sales leads, the other real listed shops), so nothing keeps
      # them in sync automatically.
      prefecture_areas = ::Area.where(parent_id: nil).index_by(&:name)
      child_area_names_by_parent_id = ::Area.where.not(parent_id: nil)
        .group_by(&:parent_id).transform_values { |areas| areas.map(&:name).to_set }
      @district_registered = @districts.index_by(&:id).transform_values do |district|
        prefecture_area = prefecture_areas[district.prefecture]
        prefecture_area.present? && child_area_names_by_parent_id[prefecture_area.id]&.include?(district.name) || false
      end
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

    # One-click registration of a district into the site's own Area
    # taxonomy: creates the prefecture-level Area first if it doesn't exist
    # yet, then the district as its child. Needs no admin input, so the
    # slug is auto-generated (not a good public URL -- rename it from
    # エリア管理 afterward) and the region is looked up from
    # Area::PREFECTURE_REGIONS.
    def register_area
      prefecture_area = ::Area.find_by(parent_id: nil, name: @district.prefecture)

      if prefecture_area.nil?
        region = ::Area.region_for_prefecture_name(@district.prefecture)
        if region.nil?
          redirect_to admin_shop_prospect_districts_path,
            alert: "「#{@district.prefecture}」の地方区分を自動判定できませんでした。お手数ですが「エリア管理」から手動で登録してください。"
          return
        end
        prefecture_area = ::Area.create!(name: @district.prefecture, slug: ::Area.generate_unique_slug, region: region, position: 0)
      end

      if ::Area.exists?(parent_id: prefecture_area.id, name: @district.name)
        redirect_to admin_shop_prospect_districts_path, alert: "既にエリアへ登録済みです。"
        return
      end

      ::Area.create!(name: @district.name, slug: ::Area.generate_unique_slug, parent: prefecture_area, position: 0)
      redirect_to admin_shop_prospect_districts_path,
        notice: "「#{@district.prefecture}ー#{@district.name}」をエリアに登録しました。URL用のスラッグは自動生成されているので、必要であれば「エリア管理」からわかりやすい値に変更してください。"
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
