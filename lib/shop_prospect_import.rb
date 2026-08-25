require "csv"
require "admin_csv_export"

# Bulk-imports/exports ShopProspect rows as CSV (see
# Admin::ShopProspectsController#import/#export). Imported rows are
# prepared by hand or exported from a spreadsheet by the admin — this
# module never fetches data from another site itself.
#
# The standard import format matches what competitor listing directories
# (e.g. mensheaven.jp) export when copy-pasted into a spreadsheet: a
# 店舗名,ジャンル (業種/エリア combined, e.g. "ソープ/吉原"), 電話番号,
# メールアドレス, URL per shop, with blank-ish rows acting as area section
# headers (e.g. "【吉原】,,,,") that should be skipped rather than imported
# as prospects.
module ShopProspectImport
  Result = Struct.new(:created_count, :error_rows, keyword_init: true)

  HEADERS = %w[店舗名 ジャンル 電話番号 メールアドレス URL].freeze

  HEADER_TO_ATTRIBUTE = {
    "店舗名" => :name,
    "ジャンル" => :genre,
    "電話番号" => :phone,
    "メールアドレス" => :email,
    "URL" => :listing_url
  }.freeze

  # A section-header row from the source spreadsheet, e.g. "【吉原】,,,," --
  # not a real shop, so it must not become a ShopProspect.
  AREA_HEADER_PATTERN = /\A【.+】\z/

  TEMPLATE_CSV = CSV.generate do |csv|
    csv << HEADERS
    csv << ["サンプル店舗", "デリヘル/新宿・歌舞伎町", "03-1234-5678", "info@example.com", "https://example.com/shop/123"]
  end.freeze

  module_function

  def call(file)
    created_count = 0
    error_rows = []

    CSV.parse(strip_bom(file.read), headers: true).each_with_index do |row, index|
      name = row["店舗名"]
      next if name.present? && name.match?(AREA_HEADER_PATTERN)

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

  EXPORT_HEADERS = %w[
    店舗名 ジャンル 地区 電話番号 メールアドレス 掲載サイト名 URL
    ステータス メール送信日時 リンククリック日時 メモ
  ].freeze

  # Wider than the import format -- includes derived/tracking columns
  # (地区, 送信・クリック日時) an admin would want in a report but that
  # importing back in wouldn't make sense for.
  def export(records)
    AdminCsvExport.call(records, EXPORT_HEADERS, {}) do |_row, record|
      [
        record.name,
        record.genre,
        record.shop_prospect_district&.display_name,
        record.phone,
        record.email,
        record.listing_site_name,
        record.listing_url,
        ApplicationHelper::STATUS_LABELS["ShopProspect"][record.status],
        record.outreach_email_sent_at,
        record.outreach_link_clicked_at,
        record.memo
      ]
    end
  end
end
