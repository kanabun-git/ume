class ReviewsController < ApplicationController
  before_action :set_shop

  def new
    @review = @shop.reviews.build
    authorize @review
  end

  def create
    # Honeypot: a field real visitors never see or fill in (hidden via CSS,
    # not `type="hidden"`, which unsophisticated bots skip). If it's
    # filled, silently pretend success rather than telling the bot it was
    # caught.
    if params.dig(:review, :website).present?
      redirect_to shop_path(@shop), notice: "口コミを投稿しました。確認後に掲載されます。" and return
    end

    @review = @shop.reviews.build(review_params)
    @review.ip_address = request.remote_ip
    @review.member = current_member if member_signed_in?
    authorize @review

    if @review.save
      redirect_to shop_path(@shop), notice: "口コミを投稿しました。確認後に掲載されます。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def helpful
    review = @shop.reviews.visible.find(params[:id])
    ReviewHelpfulVote.find_or_create_by(review: review, ip_address: request.remote_ip)
    redirect_back fallback_location: shop_path(@shop), notice: "評価ありがとうございます。"
  end

  private

  def set_shop
    @shop = Shop.visible.find(params[:shop_id])
  end

  def review_params
    params.require(:review).permit(:cast_id, :reviewer_name, :rating, :body)
  end
end
