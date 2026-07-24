module ShopAdmin
  class DiaryEntriesController < BaseController
    def index
      @diary_entries = ::DiaryEntry.joins(:cast).where(casts: { shop_id: current_shop.id })
    end

    def show
      @diary_entry = ::DiaryEntry.joins(:cast).where(casts: { shop_id: current_shop.id }).find(params[:id])
    end
  end
end
