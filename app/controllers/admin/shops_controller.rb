module Admin
  class ShopsController < BaseController
    before_action :set_shop, only: [:show, :edit, :update, :destroy, :approve, :suspend]

    def index
      @shops = policy_scope(::Shop)
    end

    def show
    end

    def new
      @shop = ::Shop.new
      authorize @shop
    end

    def create
      @shop = ::Shop.new(shop_params)
      authorize @shop

      if @shop.save
        redirect_to admin_shops_path, notice: "店舗を登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @shop.update(shop_params)
        redirect_to admin_shops_path, notice: "店舗情報を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def approve
      authorize @shop, :manage_status?
      @shop.update!(status: :approved)
      redirect_to admin_shops_path, notice: "#{@shop.name} を承認しました。"
    end

    def suspend
      authorize @shop, :manage_status?
      @shop.update!(status: :suspended)
      redirect_to admin_shops_path, notice: "#{@shop.name} を停止しました。"
    end

    def destroy
      @shop.destroy
      redirect_to admin_shops_path, notice: "店舗を削除しました。"
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:id])
      authorize @shop
    end

    def shop_params
      params.require(:shop).permit(
        :name, :area_id, :genre_id, :plan_id, :catch_copy, :description,
        :address, :phone, :business_hours, :chain_name, :editor_review,
        :price_note, :transportation_fee_note, :coverage_area_note,
        :coupon_description, :recruiting_message,
        :online_reservation, :visit_point_program, :coupon_available,
        :event_ongoing, :recruiting_cast, :recruiting_staff,
        photos: []
      )
    end
  end
end
