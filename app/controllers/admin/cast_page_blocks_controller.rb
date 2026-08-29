module Admin
  # Lets platform admins manage any shop's cast (girl detail) page blocks,
  # mirroring ShopAdmin::CastPageBlocksController but scoped by :shop_id
  # instead of the signed-in shop admin's own shop.
  class CastPageBlocksController < BaseController
    before_action :set_shop
    before_action :set_block, only: [:edit, :update, :destroy, :move_up, :move_down, :toggle_visibility, :toggle_hide_header]

    def index
      @blocks = policy_scope(::CastPageBlock).where(shop: @shop)
    end

    def new
      @block = @shop.cast_page_blocks.build(background_opacity: 1.0, layout_column: :main)
      authorize @block
    end

    def create
      @block = @shop.cast_page_blocks.build(block_params)
      @block.position = (@shop.cast_page_blocks.where(layout_column: @block.layout_column).maximum(:position) || -1) + 1
      authorize @block

      if @block.save
        redirect_to admin_shop_cast_page_blocks_path(@shop), notice: "ブロックを追加しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @block.update(block_params)
        redirect_to admin_shop_cast_page_blocks_path(@shop), notice: "ブロックを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @block.destroy
      redirect_to admin_shop_cast_page_blocks_path(@shop), notice: "ブロックを削除しました。"
    end

    def move_up
      swap_with(@shop.cast_page_blocks.where(layout_column: @block.layout_column).where("position < ?", @block.position).reorder(position: :desc).first)
      redirect_to admin_shop_cast_page_blocks_path(@shop)
    end

    def move_down
      swap_with(@shop.cast_page_blocks.where(layout_column: @block.layout_column).where("position > ?", @block.position).reorder(:position).first)
      redirect_to admin_shop_cast_page_blocks_path(@shop)
    end

    def toggle_visibility
      @block.update!(visible: !@block.visible)
      redirect_to admin_shop_cast_page_blocks_path(@shop)
    end

    def toggle_hide_header
      @block.update!(hide_header: !@block.hide_header)
      redirect_to admin_shop_cast_page_blocks_path(@shop)
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end

    def swap_with(other_block)
      return if other_block.nil?

      ::CastPageBlock.transaction do
        my_position = @block.position
        @block.update!(position: other_block.position)
        other_block.update!(position: my_position)
      end
    end

    def set_block
      @block = @shop.cast_page_blocks.find(params[:id])
      authorize @block
    end

    def block_params
      params.require(:cast_page_block).permit(:block_type, :layout_column, :title, :visible, :hide_header, :background_color, :background_opacity, settings: {})
    end
  end
end
