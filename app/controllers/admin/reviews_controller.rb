module Admin
  class ReviewsController < BaseController
    before_action :set_review, only: [:show, :destroy, :approve, :reject]

    def index
      @reviews = policy_scope(::Review).includes(:shop, :cast)
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

    private

    def set_review
      @review = ::Review.find(params[:id])
      authorize @review, :moderate?
    end
  end
end
