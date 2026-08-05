# Registers the same shift (start/end time) across every date in a range
# that falls on the selected weekdays, for one cast at once (see
# ShopAdmin::ShiftsController#create) — the "screen" half of shop admin
# bulk shift registration, the CSV half is ShiftImport.
module ShiftBulkCreate
  Result = Struct.new(:created_count, :error_rows, keyword_init: true)

  module_function

  def call(cast:, start_date:, end_date:, weekdays:, start_time:, end_time:, ends_next_day:, note:)
    created_count = 0
    error_rows = []

    (start_date..end_date).each do |date|
      next unless weekdays.include?(date.wday)

      shift = cast.shifts.build(
        work_date: date,
        start_time: start_time,
        end_time: end_time,
        ends_next_day: ends_next_day,
        note: note
      )

      if shift.save
        created_count += 1
      else
        error_rows << { date: date, errors: shift.errors.full_messages.join("、") }
      end
    end

    Result.new(created_count: created_count, error_rows: error_rows)
  end
end
