class AreasController < ApplicationController
  def show
    @area = Area.find_by!(slug: params[:slug])
    area_ids = [@area.id] + @area.children.pluck(:id)
    @shops = Shop.visible.where(area_id: area_ids).page(params[:page])
  end
end
