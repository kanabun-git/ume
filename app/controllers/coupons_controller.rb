class CouponsController < ApplicationController
  PER_PAGE = 30

  def index
    @areas = Area.all
    @genres = Genre.all
    @sort = params[:sort].presence_in(%w[discount price]) || "recommended"

    @coupons = Coupon.active.joins(:shop).merge(Shop.visible).includes(shop: [:area, :genre])
    @coupons = @coupons.where(shops: { area_id: params[:area_id] }) if params[:area_id].present?
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

    # "最安値" badge: the single cheapest active coupon for each course name,
    # computed across the whole site regardless of the filters/sort above,
    # so it stays meaningful (and stable) no matter how this page is narrowed.
    @cheapest_coupon_ids = Coupon.active.joins(:shop).merge(Shop.visible)
      .group_by(&:course_name)
      .values.map { |list| list.min_by(&:discounted_price).id }
  end
end
