module Admin
  class ShiftsController < BaseController
    def index
      @shop = ::Shop.find(params[:shop_id])
      @shifts = @shop.shifts.includes(:cast).order(:work_date)
    end
  end
end
