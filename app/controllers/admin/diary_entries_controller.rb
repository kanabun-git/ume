module Admin
  class DiaryEntriesController < BaseController
    before_action :set_shop

    def index
      @diary_entries = @shop.diary_entries.includes(:cast).order(created_at: :desc)
    end

    def show
      @diary_entry = @shop.diary_entries.find(params[:id])
      authorize @diary_entry
    end

    def destroy
      @diary_entry = @shop.diary_entries.find(params[:id])
      authorize @diary_entry

      @diary_entry.destroy
      redirect_to admin_shop_diary_entries_path(@shop), notice: "日記を削除しました。"
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end
  end
end
