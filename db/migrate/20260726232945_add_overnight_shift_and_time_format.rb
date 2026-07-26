class AddOvernightShiftAndTimeFormat < ActiveRecord::Migration[7.2]
  def change
    # Marks a shift whose end time falls on the day after work_date
    # (e.g. 20:00 -> 02:00). Without this the end-after-start validation
    # rejects overnight shifts, which are the norm in this industry.
    add_column :shifts, :ends_next_day, :boolean, default: false, null: false

    # Per-shop choice of how times past midnight are displayed:
    # 0 = standard (02:00), 1 = extended (26:00).
    add_column :shops, :time_display_format, :integer, default: 0, null: false
  end
end
