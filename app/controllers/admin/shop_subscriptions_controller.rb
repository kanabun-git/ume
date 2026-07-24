module Admin
  class ShopSubscriptionsController < BaseController
    before_action :set_shop_subscription, only: [:show, :edit, :update, :destroy]

    def index
      @shop_subscriptions = policy_scope(::ShopSubscription).includes(:shop, :plan)
    end

    def show
    end

    def new
      @shop_subscription = ::ShopSubscription.new
      authorize @shop_subscription
    end

    def create
      @shop_subscription = ::ShopSubscription.new(shop_subscription_params)
      authorize @shop_subscription

      if @shop_subscription.save
        redirect_to admin_shop_subscriptions_path, notice: "契約を登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @shop_subscription.update(shop_subscription_params)
        redirect_to admin_shop_subscriptions_path, notice: "契約を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @shop_subscription.destroy
      redirect_to admin_shop_subscriptions_path, notice: "契約を削除しました。"
    end

    private

    def set_shop_subscription
      @shop_subscription = ::ShopSubscription.find(params[:id])
      authorize @shop_subscription
    end

    def shop_subscription_params
      params.require(:shop_subscription).permit(:shop_id, :plan_id, :started_on, :ended_on, :status)
    end
  end
end
