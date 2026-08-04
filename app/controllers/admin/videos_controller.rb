module Admin
  # Lets the platform admin register 体験動画 (experience videos) for any
  # shop directly, without navigating into that shop's own block
  # management screen. Backed by the same ShopPageBlock model
  # (block_type: :movie) as shop_admin's page-block CMS — just scoped
  # across every shop, with a shop/region-focused form, and with the
  # video file-size cap lifted (see ShopPageBlock#skip_video_size_limit?).
  class VideosController < BaseController
    before_action :set_block, only: [:edit, :update, :destroy]

    def index
      @blocks = policy_scope(::ShopPageBlock).movie.includes(shop: :area).reorder(created_at: :desc).page(params[:page])
    end

    def new
      @block = ::ShopPageBlock.new(block_type: :movie, visible: true, background_opacity: 1.0)
      authorize @block
      @shops = ::Shop.order(:name)
    end

    def create
      @block = ::ShopPageBlock.new(block_params)
      @block.block_type = :movie
      @block.unlimited_video_size = true
      authorize @block

      @block.position = (@block.shop.shop_page_blocks.maximum(:position) || -1) + 1 if @block.shop

      if @block.save
        redirect_to admin_videos_path, notice: "体験動画を登録しました。"
      else
        @shops = ::Shop.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @shops = ::Shop.order(:name)
    end

    def update
      attrs = block_params.merge(unlimited_video_size: true)
      # A file_field with no new selection submits an empty string, and
      # assigning that to a has_one_attached setter purges the existing
      # attachment — so leave :video_file out entirely unless a file was chosen.
      attrs = attrs.except(:video_file) if block_params[:video_file].blank?

      if @block.update(attrs)
        redirect_to admin_videos_path, notice: "体験動画を更新しました。"
      else
        @shops = ::Shop.order(:name)
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @block.destroy
      redirect_to admin_videos_path, notice: "体験動画を削除しました。"
    end

    private

    def set_block
      @block = ::ShopPageBlock.movie.find(params[:id])
      authorize @block
    end

    def block_params
      params.require(:shop_page_block).permit(:shop_id, :title, :visible, :video_file, settings: {})
    end
  end
end
