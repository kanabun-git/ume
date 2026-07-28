module ShopAdmin
  class ReviewsController < BaseController
    def index
      authorize ::Review, :index?
      @reviews = policy_scope(::Review)
    end

    def reply
      review = policy_scope(::Review).find(params[:id])
      authorize review, :reply?

      review.update!(shop_reply: params[:shop_reply], shop_replied_at: Time.current)
      redirect_to shop_admin_reviews_path, notice: "返信を投稿しました。"
    end
  end
end
