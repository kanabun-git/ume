module ShopAdmin
  class ReviewsController < BaseController
    def index
      authorize ::Review, :index?
      @reviews = policy_scope(::Review)
    end
  end
end
