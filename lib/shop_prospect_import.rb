require "csv"

# Bulk-imports ShopProspect rows from an admin-uploaded CSV (see
# Admin::ShopProspectsController#import). Rows are prepared by hand or
# exported from a spreadsheet by the admin — this module never fetches
# data from another site itself.
module ShopProspectImport
  Result = Struct.new(:created_count, :error_rows, keyword_init: true)

  HEADERS = %w[店舗名 電話番号 メールアドレス 掲載サイト名 掲載URL メモ].freeze

  HEADER_TO_ATTRIBUTE = {
    "店舗名" => :name,
    "電話番号" => :phone,
    "メールアドレス" => :email,
    "掲載サイト名" => :listing_site_name,
    "掲載URL" => :listing_url,
    "メモ" => :memo
  }.freeze

  TEMPLATE_CSV = CSV.generate do |csv|
    csv << HEADERS
    csv << ["サンプル店舗", "03-1234-5678", "info@example.com", "○○ネット", "https://example.com/shop/123", "電話予約可、担当:田中様"]
  end.freeze

  module_function

  def call(file)
    created_count = 0
    error_rows = []

    CSV.parse(strip_bom(file.read), headers: true).each_with_index do |row, index|
      attrs = HEADER_TO_ATTRIBUTE.each_with_object({}) { |(header, attribute), memo| memo[attribute] = row[header] }
      prospect = ShopProspect.new(attrs)

      if prospect.save
        created_count += 1
      else
        error_rows << { line: index + 2, errors: prospect.errors.full_messages.join("、") }
      end
    end

    Result.new(created_count: created_count, error_rows: error_rows)
  end

  # Strips a leading UTF-8 byte-order mark, which Excel adds when saving
  # CSVs on Windows — without this, the first header ("店舗名") would fail
  # to match and every row would be rejected.
  def strip_bom(content)
    content = content.dup.force_encoding(Encoding::UTF_8)
    content.delete_prefix("﻿")
  end
end
