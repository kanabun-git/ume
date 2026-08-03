module Admin
  # Lets platform admins manage any shop's reply templates, mirroring
  # ShopAdmin::ReviewReplyTemplatesController but scoped by :shop_id instead
  # of the signed-in shop admin's own shop.
  class ReviewReplyTemplatesController < BaseController
    before_action :set_shop
    before_action :set_template, only: [:edit, :update, :destroy]

    def index
      @templates = policy_scope(::ReviewReplyTemplate).where(shop: @shop)
    end

    def new
      @template = @shop.review_reply_templates.build
      authorize @template
    end

    def create
      @template = @shop.review_reply_templates.build(template_params)
      authorize @template

      if @template.save
        redirect_to admin_shop_review_reply_templates_path(@shop), notice: "返信テンプレートを追加しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @template.update(template_params)
        redirect_to admin_shop_review_reply_templates_path(@shop), notice: "返信テンプレートを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @template.destroy
      redirect_to admin_shop_review_reply_templates_path(@shop), notice: "返信テンプレートを削除しました。"
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end

    def set_template
      @template = @shop.review_reply_templates.find(params[:id])
      authorize @template
    end

    def template_params
      params.require(:review_reply_template).permit(:title, :body)
    end
  end
end
