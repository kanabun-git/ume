require "csv"
require "admin_csv_import"

# Bulk-imports Genre rows from an admin-uploaded CSV (see
# Admin::GenresController#import).
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
end
