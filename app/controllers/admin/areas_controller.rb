module Admin
  class AreasController < BaseController
    before_action :set_area, only: [:show, :edit, :update, :destroy]

    def index
      @areas = policy_scope(::Area)
    end

    def show
    end

    def new
      @area = ::Area.new
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
