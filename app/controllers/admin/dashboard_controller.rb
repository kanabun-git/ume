module Admin
  class DashboardController < BaseController
    def show
      @pending_shops_count = ::Shop.pending.count
      @pending_reviews_count = ::Review.pending.count
      @shops_count = ::Shop.count
      @casts_count = ::Cast.count
    end
  end
end
