# See ShopAdmin::ShopPointTransactionsController.
module Admin
  class ShopPointTransactionsController < BaseController
    before_action :set_shop_membership
    before_action :set_shop_point_transaction, only: [:edit, :update, :destroy]

    def create
      if @shop_membership.shop_point_transactions.create(transaction_params)
        redirect_to admin_shop_shop_membership_path(@shop, @shop_membership), notice: "ポイントを記録しました。"
      else
        redirect_to admin_shop_shop_membership_path(@shop, @shop_membership), alert: "ポイントの記録に失敗しました。"
      end
    end

    def edit
    end

    def update
      if @shop_point_transaction.update(transaction_params)
        redirect_to admin_shop_shop_membership_path(@shop, @shop_membership), notice: "ポイント履歴を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @shop_point_transaction.destroy
      redirect_to admin_shop_shop_membership_path(@shop, @shop_membership), notice: "ポイント履歴を削除しました。"
    end

    private

    def set_shop_membership
      @shop = ::Shop.find(params[:shop_id])
      @shop_membership = @shop.shop_memberships.find(params[:shop_membership_id])
      authorize @shop_membership, :update?
    end

    def set_shop_point_transaction
      @shop_point_transaction = @shop_membership.shop_point_transactions.find(params[:id])
    end

    def transaction_params
      params.require(:shop_point_transaction).permit(:amount, :reason)
    end
  end
end
