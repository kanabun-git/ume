module Admin
  class ShopsController < BaseController
    before_action :set_shop, only: [:show, :edit, :update, :destroy, :approve, :suspend, :confirm_design]

    def index
      @shops = policy_scope(::Shop)
    end

    def show
    end

    def new
      # `shop_name` may arrive from a shop registration inquiry's "この内容
      # で登録する" link (see admin/shop_inquiries/show) — it only prefills
      # a GET form field, so accepting it outside shop_params is safe.
      @shop = ::Shop.new(name: params[:shop_name])
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
      attrs = shop_params.except(:photos)

      if update_with_appended_images(@shop, attachment_name: :photos, new_files: shop_params[:photos], other_attrs: attrs)
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

    # Acknowledges a shop admin's published design change (see
    # Shop#publish!) -- doesn't gate the publish itself, just clears the
    # "デザイン変更あり" notice once the platform admin has looked it over.
    def confirm_design
      @shop.confirm_design_reviewed!
      redirect_to admin_shops_path, notice: "#{@shop.name} のデザイン変更を確認済みにしました。"
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:id])
      # approve/suspend authorize explicitly against :manage_status? below,
      # since ShopPolicy has no approve?/suspend? methods for Pundit to infer.
      authorize @shop unless %w[approve suspend].include?(action_name)
    end

    def shop_params
      params.require(:shop).permit(
        :name, :area_id, :genre_id, :plan_id, :catch_copy, :description,
        :address, :phone, :business_hours, :chain_name, :editor_review,
        :price_note, :min_price, :transportation_fee_note, :coverage_area_note,
        :coupon_description, :recruiting_message,
        :online_reservation, :visit_point_program, :coupon_available,
        :event_ongoing, :recruiting_cast, :recruiting_staff, :zero_recommended,
        photos: []
      )
    end
  end
end
