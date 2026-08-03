module Admin
  class ReviewsController < BaseController
    before_action :set_review, only: [:show, :destroy, :approve, :reject]

    def index
      @reviews = policy_scope(::Review).includes(:shop, :cast)
      @templates_by_shop = ::ReviewReplyTemplate.where(shop_id: @reviews.map(&:shop_id).uniq).group_by(&:shop_id)
    end

    def show
    end

    def approve
      authorize @review, :moderate?
      @review.update!(status: :approved)
      redirect_to admin_reviews_path, notice: "口コミを承認しました。"
    end

    def reject
      authorize @review, :moderate?
      @review.update!(status: :rejected)
      redirect_to admin_reviews_path, notice: "口コミを却下しました。"
    end

    def destroy
      @review.destroy
      redirect_to admin_reviews_path, notice: "口コミを削除しました。"
    end

    def reply
      review = policy_scope(::Review).find(params[:id])
      authorize review, :reply?

      review.update!(shop_reply: params[:shop_reply], shop_replied_at: Time.current)
      redirect_to admin_reviews_path, notice: "返信を投稿しました。"
    end

    private

    def set_review
      @review = ::Review.find(params[:id])
      authorize @review, :moderate?
    end
  end
end
