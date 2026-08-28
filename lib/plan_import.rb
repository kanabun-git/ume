require "csv"
require "csv_bom"
require "admin_csv_import"
require "admin_csv_export"

# Bulk-imports/exports Plan rows as CSV (see Admin::PlansController
# #import/#export).
module PlanImport
  HEADERS = %w[名前 月額料金 表示優先度 表示順].freeze

  HEADER_TO_ATTRIBUTE = {
    "名前" => :name,
    "月額料金" => :monthly_fee,
    "表示優先度" => :priority_weight,
    "表示順" => :position
  }.freeze

  TEMPLATE_CSV = CsvBom.wrap(CSV.generate do |csv|
    csv << HEADERS
    csv << ["スタンダードプラン", "30000", "1", "1"]
  end).freeze

  module_function

  def call(file)
    AdminCsvImport.call(::Plan, file, HEADER_TO_ATTRIBUTE)
  end

  def export(records)
    AdminCsvExport.call(records, HEADERS, HEADER_TO_ATTRIBUTE)
  end
end
