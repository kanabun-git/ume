module Admin
  class AreasController < BaseController
    before_action :set_area, only: [:show, :edit, :update, :destroy]

    def index
      @areas = policy_scope(::Area)
    end

    def show
    end

    def new
      # `name`/`parent_id` may arrive from 地区管理's "エリアに追加" link (see
      # admin/shop_prospect_districts/index) -- they only prefill this GET
      # form. parent_id is re-validated against real top-level areas here
      # rather than trusted from the query string as-is.
      parent_id = ::Area.where(parent_id: nil).where(id: params[:parent_id]).pick(:id)
      @area = ::Area.new(name: params[:name], parent_id: parent_id)
      authorize @area
    end

    def create
      @area = ::Area.new(area_params)
      authorize @area

      if @area.save
        redirect_to admin_areas_path, notice: "エリアを登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @area.update(area_params)
        redirect_to admin_areas_path, notice: "エリアを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @area.destroy
      redirect_to admin_areas_path, notice: "エリアを削除しました。"
    end

    def import
      authorize ::Area.new, :import?

      if params[:file].blank?
        redirect_to admin_areas_path, alert: "CSVファイルを選択してください。"
        return
      end

      result = ::AreaImport.call(params[:file])
      redirect_to admin_areas_path, notice: import_notice(result)
    end

    def template
      authorize ::Area.new, :import?
      send_data ::AreaImport::TEMPLATE_CSV, filename: "areas_template.csv", type: "text/csv"
    end

    def export
      authorize ::Area.new, :export?
      send_data ::AreaImport.export(policy_scope(::Area)), filename: "areas_#{Date.current}.csv", type: "text/csv"
    end

    private

    def set_area
      @area = ::Area.find(params[:id])
      authorize @area
    end

    def area_params
      params.require(:area).permit(:name, :name_kana, :slug, :region, :parent_id, :position)
    end
  end
end
