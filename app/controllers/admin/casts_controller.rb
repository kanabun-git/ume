module Admin
  class CastsController < BaseController
    before_action :set_shop
    before_action :set_cast, only: [:show, :edit, :update, :destroy]

    def index
      @casts = @shop.casts
    end

    def show
    end

    def new
      @cast = @shop.casts.build
      @cast.build_user
      authorize @cast
    end

    def create
      @cast = @shop.casts.build(cast_params)
      authorize @cast

      if @cast.save
        redirect_to admin_shop_casts_path(@shop), notice: "キャストを登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = cast_params.except(:user_attributes, :photos)

      if update_with_appended_images(@cast, attachment_name: :photos, new_files: cast_params[:photos], other_attrs: attrs)
        redirect_to admin_shop_casts_path(@shop), notice: "キャスト情報を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @cast.destroy
      redirect_to admin_shop_casts_path(@shop), notice: "キャストを削除しました。"
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end

    def set_cast
      @cast = @shop.casts.find(params[:id])
      authorize @cast
    end

    def cast_params
      params.require(:cast).permit(
        :name, :alias_name, :age, :height, :bust, :waist, :hip, :cup,
        :catch_copy, :description, :status, :is_trial, :manager_recommended,
        :pick_up, :manager_comment, photos: [],
        user_attributes: [:email, :password, :password_confirmation]
      )
    end
  end
end
