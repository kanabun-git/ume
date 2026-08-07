require "csv"
require "admin_csv_import"
require "admin_csv_export"

# Bulk-imports/exports MemberRank rows as CSV (see
# Admin::MemberRanksController#import/#export).
module MemberRankImport
  HEADERS = %w[ランク名 必要承認件数].freeze

  HEADER_TO_ATTRIBUTE = {
    "ランク名" => :name,
    "必要承認件数" => :min_approved_count
  }.freeze

  TEMPLATE_CSV = CSV.generate do |csv|
    csv << HEADERS
    csv << ["ブロンズ会員", "1"]
  end.freeze

  module_function

  def call(file)
    AdminCsvImport.call(::MemberRank, file, HEADER_TO_ATTRIBUTE)
  end

  def export(records)
    AdminCsvExport.call(records, HEADERS, HEADER_TO_ATTRIBUTE)
  end
end
