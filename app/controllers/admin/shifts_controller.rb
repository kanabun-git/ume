module Admin
  class ShiftsController < BaseController
    before_action :set_shop

    def index
      @shifts = @shop.shifts.includes(:cast).order(:work_date)
    end

    def new
      @casts = @shop.casts.visible
    end

    def create
      cast = @shop.casts.find(params[:cast_id])
      authorize cast.shifts.build

      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])

      if start_date > end_date
        redirect_to admin_shop_shifts_path(@shop), alert: "開始日は終了日より前にしてください。"
        return
      end

      if (end_date - start_date).to_i > 366
        redirect_to admin_shop_shifts_path(@shop), alert: "一度に指定できる期間は366日までです。"
        return
      end

      result = ::ShiftBulkCreate.call(
        cast: cast,
        start_date: start_date,
        end_date: end_date,
        weekdays: Array(params[:weekdays]).map(&:to_i),
        start_time: params[:start_time],
        end_time: params[:end_time],
        ends_next_day: params[:ends_next_day] == "1",
        note: params[:note]
      )

      redirect_to admin_shop_shifts_path(@shop), notice: bulk_result_notice(result)
    rescue ArgumentError, TypeError
      redirect_to admin_shop_shifts_path(@shop), alert: "日付の形式が正しくありません。"
    end

    def destroy
      shift = @shop.shifts.find(params[:id])
      authorize shift

      shift.destroy
      redirect_to admin_shop_shifts_path(@shop), notice: "出勤予定を削除しました。"
    end

    def import
      if params[:file].blank?
        redirect_to admin_shop_shifts_path(@shop), alert: "CSVファイルを選択してください。"
        return
      end

      result = ::ShiftImport.call(params[:file], shop: @shop)
      redirect_to admin_shop_shifts_path(@shop), notice: import_result_notice(result)
    end

    def template
      send_data ::ShiftImport::TEMPLATE_CSV, filename: "shifts_template.csv", type: "text/csv"
    end

    private

    def set_shop
      @shop = ::Shop.find(params[:shop_id])
    end

    def bulk_result_notice(result)
      notice = "#{result.created_count}件登録しました。"
      return notice if result.error_rows.empty?

      notice + "(#{result.error_rows.size}件はエラーのためスキップしました: " \
        "#{result.error_rows.map { |r| "#{r[:date]}(#{r[:errors]})" }.join('、')})"
    end

    def import_result_notice(result)
      notice = "#{result.created_count}件登録しました。"
      return notice if result.error_rows.empty?

      notice + "(#{result.error_rows.size}件はエラーのためスキップしました。1行目はヘッダー行です: " \
        "#{result.error_rows.map { |r| "#{r[:line]}行目(#{r[:errors]})" }.join('、')})"
    end
  end
end
