class ReviewsController < ApplicationController
  before_action :set_shop

  def new
    @review = @shop.reviews.build
    authorize @review
  end

  def create
    @review = @shop.reviews.build(review_params)
    authorize @review

    if @review.save
      redirect_to shop_path(@shop), notice: "口コミを投稿しました。確認後に掲載されます。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_shop
    @shop = Shop.visible.find(params[:shop_id])
  end

  def review_params
    params.require(:review).permit(:cast_id, :reviewer_name, :rating, :body)
  end
end
