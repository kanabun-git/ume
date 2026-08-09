module Admin
  class ShopMemberBenefitsController < BaseController
    before_action :set_shop
    before_action :set_shop_member_rank
    before_action :set_shop_member_benefit, only: [:edit, :update, :destroy]

    def new
      @shop_member_benefit = @shop_member_rank.shop_member_benefits.build
      authorize @shop_member_benefit
    end

    def create
      @shop_member_benefit = @shop_member_rank.shop_member_benefits.build(shop_member_benefit_params)
      authorize @shop_member_benefit

      if @shop_member_benefit.save
        redirect_to admin_shop_shop_member_ranks_path(@shop), notice: "特典を登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @shop_member_benefit.update(shop_member_benefit_params)
        redirect_to admin_shop_shop_member_ranks_path(@shop), notice: "特典を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @shop_member_benefit.destroy
      redirect_to admin_shop_shop_member_ranks_path(@shop), notice: "特典を削除しました。"
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end

    def set_shop_member_rank
      @shop_member_rank = @shop.shop_member_ranks.find(params[:shop_member_rank_id])
    end

    def set_shop_member_benefit
      @shop_member_benefit = @shop_member_rank.shop_member_benefits.find(params[:id])
      authorize @shop_member_benefit
    end

    def shop_member_benefit_params
      params.require(:shop_member_benefit).permit(:name, :description, :benefit_type)
    end
  end
end
