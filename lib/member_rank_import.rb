require "csv"
require "admin_csv_import"

# Bulk-imports MemberRank rows from an admin-uploaded CSV (see
# Admin::MemberRanksController#import).
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
end
