require "csv"
require "csv_bom"

# Bulk-imports Shift rows from a shop-admin-uploaded CSV (see
# ShopAdmin::ShiftsController#import). Each row is matched to one of the
# shop's own casts by name — a row naming a cast at another shop, or no
# cast at all, is skipped as an error row rather than silently misfiled.
module ShiftImport
  Result = Struct.new(:created_count, :error_rows, keyword_init: true)

  HEADERS = %w[キャスト名 勤務日 開始時刻 終了時刻 翌日にまたぐ メモ].freeze

  TEMPLATE_CSV = CsvBom.wrap(CSV.generate do |csv|
    csv << HEADERS
    csv << ["ゆい", "2026-08-10", "18:00", "02:00", "true", "体験入店"]
  end).freeze

  module_function

  def call(file, shop:)
    created_count = 0
    error_rows = []

    CSV.parse(strip_bom(file.read), headers: true).each_with_index do |row, index|
      cast_name = row["キャスト名"].to_s.strip
      cast = shop.casts.find_by(name: cast_name)

      if cast.nil?
        error_rows << { line: index + 2, errors: "キャスト「#{cast_name}」が見つかりません" }
        next
      end

      shift = cast.shifts.build(
        work_date: row["勤務日"],
        start_time: row["開始時刻"],
        end_time: row["終了時刻"],
        ends_next_day: ActiveModel::Type::Boolean.new.cast(row["翌日にまたぐ"]),
        note: row["メモ"]
      )

      if shift.save
        created_count += 1
      else
        error_rows << { line: index + 2, errors: shift.errors.full_messages.join("、") }
      end
    end

    Result.new(created_count: created_count, error_rows: error_rows)
  end

  # Strips a leading UTF-8 byte-order mark, which Excel adds when saving
  # CSVs on Windows — without this, the first header ("キャスト名") would
  # fail to match and every row would be rejected.
  def strip_bom(content)
    content = content.dup.force_encoding(Encoding::UTF_8)
    content.delete_prefix("﻿")
  end
end
