require "csv"
require "admin_csv_import"

# Bulk-imports Plan rows from an admin-uploaded CSV (see
# Admin::PlansController#import).
module PlanImport
  HEADERS = %w[名前 月額料金 表示優先度 表示順].freeze

  HEADER_TO_ATTRIBUTE = {
    "名前" => :name,
    "月額料金" => :monthly_fee,
    "表示優先度" => :priority_weight,
    "表示順" => :position
  }.freeze

  TEMPLATE_CSV = CSV.generate do |csv|
    csv << HEADERS
    csv << ["スタンダードプラン", "30000", "1", "1"]
  end.freeze

  module_function

  def call(file)
    AdminCsvImport.call(::Plan, file, HEADER_TO_ATTRIBUTE)
  end
end
