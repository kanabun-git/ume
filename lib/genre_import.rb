require "csv"
require "admin_csv_import"
require "admin_csv_export"

# Bulk-imports/exports Genre rows as CSV (see Admin::GenresController
# #import/#export).
module GenreImport
  HEADERS = %w[名前 スラッグ 表示順].freeze

  HEADER_TO_ATTRIBUTE = {
    "名前" => :name,
    "スラッグ" => :slug,
    "表示順" => :position
  }.freeze

  TEMPLATE_CSV = CSV.generate do |csv|
    csv << HEADERS
    csv << ["ソープ", "soap", "1"]
  end.freeze

  module_function

  def call(file)
    AdminCsvImport.call(::Genre, file, HEADER_TO_ATTRIBUTE)
  end

  def export(records)
    AdminCsvExport.call(records, HEADERS, HEADER_TO_ATTRIBUTE)
  end
end
