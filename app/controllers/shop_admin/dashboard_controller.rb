module ShopAdmin
  class DashboardController < BaseController
    def show
      @shop = current_shop
      @casts = @shop.casts.limit(5)
      @recent_reviews = @shop.reviews.limit(5)
    end
  end
end
