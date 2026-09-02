module ShopAdmin
  class ShopVisitsController < BaseController
    before_action :set_shop_membership
    before_action :set_shop_visit, only: [:edit, :update]

    def create
      @shop_membership.record_visit!(
        visited_at: parse_visited_at || Time.current,
        points_earned: visit_params[:points_earned].to_i,
        memo: visit_params[:memo],
        cast: find_cast,
        designation: visit_params[:designation].presence,
        duration_minutes: visit_params[:duration_minutes].presence
      )
      redirect_to shop_admin_shop_membership_path(@shop_membership), notice: "利用履歴を記録しました。"
    rescue ActiveRecord::RecordInvalid
      redirect_to shop_admin_shop_membership_path(@shop_membership), alert: "利用履歴の記録に失敗しました。"
    end

    def edit
    end

    def update
      attrs = visit_params.except(:visited_on_date, :visited_on_time, :cast_id)
        .merge(visited_at: parse_visited_at || @shop_visit.visited_at, cast: find_cast)

      if @shop_visit.update(attrs)
        redirect_to shop_admin_shop_membership_path(@shop_membership), notice: "利用履歴を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_shop_membership
      @shop_membership = current_shop.shop_memberships.find(params[:shop_membership_id])
      authorize @shop_membership, :update?
    end

    def set_shop_visit
      @shop_visit = @shop_membership.shop_visits.find(params[:id])
    end

    def parse_visited_at
      date = visit_params[:visited_on_date].presence
      return nil unless date

      time = visit_params[:visited_on_time].presence || "00:00"
      Time.zone.parse("#{date} #{time}")
    end

    def find_cast
      return nil if visit_params[:cast_id].blank?

      current_shop.casts.find(visit_params[:cast_id])
    end

    def visit_params
      params.require(:shop_visit).permit(:visited_on_date, :visited_on_time, :points_earned, :memo, :cast_id, :designation, :duration_minutes)
    end
  end
end
