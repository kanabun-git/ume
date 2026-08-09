module Admin
  class ShopMemberRanksController < BaseController
    before_action :set_shop
    before_action :set_shop_member_rank, only: [:edit, :update, :destroy]

    def index
      @shop_member_ranks = @shop.shop_member_ranks.includes(:shop_member_benefits)
    end

    def new
      @shop_member_rank = @shop.shop_member_ranks.build
      authorize @shop_member_rank
    end

    def create
      @shop_member_rank = @shop.shop_member_ranks.build(shop_member_rank_params)
      authorize @shop_member_rank

      if @shop_member_rank.save
        redirect_to admin_shop_shop_member_ranks_path(@shop), notice: "会員ランクを登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @shop_member_rank.update(shop_member_rank_params)
        redirect_to admin_shop_shop_member_ranks_path(@shop), notice: "会員ランクを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @shop_member_rank.destroy
      redirect_to admin_shop_shop_member_ranks_path(@shop), notice: "会員ランクを削除しました。"
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end

    def set_shop_member_rank
      @shop_member_rank = @shop.shop_member_ranks.find(params[:id])
      authorize @shop_member_rank
    end

    def shop_member_rank_params
      params.require(:shop_member_rank).permit(:name, :min_visit_count)
    end
  end
end
