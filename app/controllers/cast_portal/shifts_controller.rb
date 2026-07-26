module CastPortal
  class ShiftsController < BaseController
    before_action :set_shift, only: [:edit, :update, :destroy]

    def index
      @shifts = policy_scope(::Shift)
    end

    def new
      @shift = current_cast_profile.shifts.build
      authorize @shift
    end

    def create
      @shift = current_cast_profile.shifts.build(shift_params)
      authorize @shift

      if @shift.save
        redirect_to cast_shifts_path, notice: "出勤予定を登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @shift.update(shift_params)
        redirect_to cast_shifts_path, notice: "出勤予定を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @shift.destroy
      redirect_to cast_shifts_path, notice: "出勤予定を削除しました。"
    end

    private

    def set_shift
      @shift = policy_scope(::Shift).find(params[:id])
      authorize @shift
    end

    def shift_params
      params.require(:shift).permit(:work_date, :start_time, :end_time, :ends_next_day, :note, :status)
    end
  end
end
