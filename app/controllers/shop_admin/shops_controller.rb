module ShopAdmin
  class ShopsController < BaseController
    before_action :set_shop

    def edit
      authorize @shop, :update?
    end

    def update
      authorize @shop, :update?
      attrs = shop_params.except(:photos)

      if update_with_appended_images(@shop, attachment_name: :photos, new_files: shop_params[:photos], other_attrs: attrs)
        redirect_to shop_admin_root_path, notice: "店舗情報を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def publish
      authorize @shop, :update?
      @shop.publish!
      redirect_to shop_admin_root_path, notice: "店舗ページを公開しました。公開ページに表示されます。"
    end

    def unpublish
      authorize @shop, :update?
      @shop.unpublish!
      redirect_to shop_admin_root_path, notice: "店舗ページを非公開(下書き)にしました。公開ページからは見えなくなります。"
    end

    def destroy_photo
      authorize @shop, :destroy_photo?
      @shop.photos.find(params[:photo_id]).purge
      redirect_to edit_shop_admin_shop_path, notice: "写真を削除しました。"
    end

    private

    def set_shop
      @shop = current_shop
    end

    # Content fields only — status/plan/area/genre, and editorial fields
    # (chain_name/editor_review), go through the platform admin back office
    # (see Admin::ShopsController).
    def shop_params
      attrs = params.require(:shop).permit(
        :catch_copy, :description, :address, :phone, :business_hours, :time_display_format,
        :price_note, :min_price, :transportation_fee_note, :coverage_area_note,
        :coupon_description, :recruiting_message,
        :online_reservation, :visit_point_program, :coupon_available,
        :event_ongoing, :recruiting_cast, :recruiting_staff, :pr_badge_until,
        :page_background_color, :page_text_color, :page_accent_color, :page_background_image,
        photos: []
      )
      if attrs[:page_background_image].present?
        # A new file was chosen -- has_one_attached's setter replaces the
        # existing attachment (if any) with this one on save.
      elsif params.dig(:shop, :remove_page_background_image) == "1"
        # No new file, but the admin explicitly asked to clear the current
        # one -- assigning nil detaches/purges it.
        attrs[:page_background_image] = nil
      else
        # A blank file field submits "" for the attachment, which
        # has_one_attached's setter treats as "remove the current file" --
        # only pass it through when the admin actually chose a new file or
        # asked to remove it, so leaving both alone keeps the image as-is.
        attrs.delete(:page_background_image)
      end
      attrs
    end
  end
end
