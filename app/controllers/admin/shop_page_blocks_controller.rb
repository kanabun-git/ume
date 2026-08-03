module Admin
  # Lets platform admins manage any shop's page blocks, mirroring
  # ShopAdmin::ShopPageBlocksController but scoped by :shop_id instead of
  # the signed-in shop admin's own shop.
  class ShopPageBlocksController < BaseController
    before_action :set_shop
    before_action :set_block, only: [:edit, :update, :destroy, :move_up, :move_down, :toggle_visibility]

    def index
      @blocks = policy_scope(::ShopPageBlock).where(shop: @shop)
    end

    def new
      @block = @shop.shop_page_blocks.build(background_opacity: 1.0)
      authorize @block
    end

    def create
      @block = @shop.shop_page_blocks.build(block_params)
      @block.position = (@shop.shop_page_blocks.maximum(:position) || -1) + 1
      authorize @block

      if @block.save
        redirect_to admin_shop_shop_page_blocks_path(@shop), notice: "ブロックを追加しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = block_params
      # A file_field with no new selection submits an empty string, and
      # assigning that to a has_one_attached setter purges the existing
      # attachment — so leave :video_file out entirely unless a file was chosen.
      attrs = attrs.except(:video_file) if block_params[:video_file].blank?

      if @block.update(attrs)
        redirect_to admin_shop_shop_page_blocks_path(@shop), notice: "ブロックを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @block.destroy
      redirect_to admin_shop_shop_page_blocks_path(@shop), notice: "ブロックを削除しました。"
    end

    def move_up
      swap_with(@shop.shop_page_blocks.where("position < ?", @block.position).reorder(position: :desc).first)
      redirect_to admin_shop_shop_page_blocks_path(@shop)
    end

    def move_down
      swap_with(@shop.shop_page_blocks.where("position > ?", @block.position).reorder(:position).first)
      redirect_to admin_shop_shop_page_blocks_path(@shop)
    end

    def toggle_visibility
      @block.update!(visible: !@block.visible)
      redirect_to admin_shop_shop_page_blocks_path(@shop)
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end

    def swap_with(other_block)
      return if other_block.nil?

      ::ShopPageBlock.transaction do
        my_position = @block.position
        @block.update!(position: other_block.position)
        other_block.update!(position: my_position)
      end
    end

    def set_block
      @block = @shop.shop_page_blocks.find(params[:id])
      authorize @block
    end

    def block_params
      params.require(:shop_page_block).permit(:block_type, :title, :visible, :hide_header, :background_color, :background_opacity, :video_file, settings: {})
    end
  end
end
