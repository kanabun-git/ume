module ShopAdmin
  class CastPageBlocksController < BaseController
    before_action :set_block, only: [:edit, :update, :destroy, :move_up, :move_down, :toggle_visibility]

    def index
      @blocks = policy_scope(::CastPageBlock).where(shop: current_shop)
    end

    def new
      @block = current_shop.cast_page_blocks.build(background_opacity: 1.0, layout_column: :main)
      authorize @block
    end

    def create
      @block = current_shop.cast_page_blocks.build(block_params)
      @block.position = (current_shop.cast_page_blocks.where(layout_column: @block.layout_column).maximum(:position) || -1) + 1
      authorize @block

      if @block.save
        redirect_to shop_admin_cast_page_blocks_path, notice: "ブロックを追加しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @block.update(block_params)
        redirect_to shop_admin_cast_page_blocks_path, notice: "ブロックを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @block.destroy
      redirect_to shop_admin_cast_page_blocks_path, notice: "ブロックを削除しました。"
    end

    def move_up
      swap_with(current_shop.cast_page_blocks.where(layout_column: @block.layout_column).where("position < ?", @block.position).order(position: :desc).first)
      redirect_to shop_admin_cast_page_blocks_path
    end

    def move_down
      swap_with(current_shop.cast_page_blocks.where(layout_column: @block.layout_column).where("position > ?", @block.position).order(:position).first)
      redirect_to shop_admin_cast_page_blocks_path
    end

    def toggle_visibility
      @block.update!(visible: !@block.visible)
      redirect_to shop_admin_cast_page_blocks_path
    end

    private

    def swap_with(other_block)
      return if other_block.nil?

      CastPageBlock.transaction do
        my_position = @block.position
        @block.update!(position: other_block.position)
        other_block.update!(position: my_position)
      end
    end

    def set_block
      @block = current_shop.cast_page_blocks.find(params[:id])
      authorize @block
    end

    def block_params
      params.require(:cast_page_block).permit(:block_type, :layout_column, :title, :visible, :background_color, :background_opacity, settings: {})
    end
  end
end
