module Admin
  class PlansController < BaseController
    before_action :set_plan, only: [:show, :edit, :update, :destroy]

    def index
      @plans = policy_scope(::Plan)
    end

    def show
    end

    def new
      @plan = ::Plan.new
      authorize @plan
    end

    def create
      @plan = ::Plan.new(plan_params)
      authorize @plan

      if @plan.save
        redirect_to admin_plans_path, notice: "プランを登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @plan.update(plan_params)
        redirect_to admin_plans_path, notice: "プランを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @plan.destroy
      redirect_to admin_plans_path, notice: "プランを削除しました。"
    end

    def import
      authorize ::Plan.new, :import?

      if params[:file].blank?
        redirect_to admin_plans_path, alert: "CSVファイルを選択してください。"
        return
      end

      result = ::PlanImport.call(params[:file])
      redirect_to admin_plans_path, notice: import_notice(result)
    end

    def template
      authorize ::Plan.new, :import?
      send_data ::PlanImport::TEMPLATE_CSV, filename: "plans_template.csv", type: "text/csv"
    end

    def export
      authorize ::Plan.new, :export?
      send_data ::PlanImport.export(policy_scope(::Plan)), filename: "plans_#{Date.current}.csv", type: "text/csv"
    end

    private

    def set_plan
      @plan = ::Plan.find(params[:id])
      authorize @plan
    end

    def plan_params
      params.require(:plan).permit(:name, :monthly_fee, :priority_weight, :position)
    end
  end
end
