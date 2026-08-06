class CouponsController < ApplicationController
  PER_PAGE = 30

  def index
    @areas = Area.where(parent_id: nil).includes(:children)
    @genres = Genre.all
    @sort = params[:sort].presence_in(%w[discount price]) || "recommended"

    @coupons = Coupon.active.joins(:shop).merge(Shop.visible).includes(shop: [:area, :genre])
    if params[:area_id].present? && (area = Area.find_by(id: params[:area_id]))
      # A prefecture-level area has no shops of its own -- every shop sits
      # under one of its children -- so selecting it must match those
      # children's ids too, or it silently returns zero results.
      area_ids = area.prefecture? ? [area.id] + area.children.ids : [area.id]
      @coupons = @coupons.where(shops: { area_id: area_ids })
    end
    @coupons = @coupons.where(shops: { genre_id: params[:genre_id] }) if params[:genre_id].present?
    @coupons = @coupons.where(net_reservation_only: true) if params[:net_reservation_only].present?
    if params[:reviewed_only].present?
      @coupons = @coupons.where(shops: { id: Shop.visible.joins(:reviews).merge(Review.visible).select(:id) })
    end

    @coupons =
      case @sort
      when "discount"
        @coupons.reorder(Arel.sql("(100 - (coupons.discounted_price * 100.0 / coupons.regular_price)) DESC"))
      when "price"
        @coupons.reorder(:discounted_price)
      else
        @coupons
      end

    @total_count = @coupons.count
    @coupons = @coupons.page(params[:page]).per(PER_PAGE)

    # Computed across the whole site regardless of the filters/sort above,
    # so it stays meaningful (and stable) no matter how this page is narrowed.
    @cheapest_coupon_ids = Coupon.cheapest_ids_by_course
  end
end
