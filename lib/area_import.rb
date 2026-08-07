require "csv"
require "admin_csv_import"
require "admin_csv_export"

# Bulk-imports/exports Area rows as CSV (see Admin::AreasController
# #import/#export). A spreadsheet can't reference a parent row by database
# id, so the parent is looked up/written by its slug instead -- blank for a
# prefecture-level row.
module AreaImport
  HEADERS = %w[名前 カナ スラッグ 地方 表示順 親エリアのスラッグ].freeze

  HEADER_TO_ATTRIBUTE = {
    "名前" => :name,
    "カナ" => :name_kana,
    "スラッグ" => :slug,
    "地方" => :region,
    "表示順" => :position
  }.freeze

  TEMPLATE_CSV = CSV.generate do |csv|
    csv << HEADERS
    csv << ["東京都", "とうきょうと", "tokyo", "関東", "1", ""]
    csv << ["新宿", "しんじゅく", "shinjuku", "", "1", "tokyo"]
  end.freeze

  module_function

  def call(file)
    AdminCsvImport.call(::Area, file, HEADER_TO_ATTRIBUTE) do |attrs, row|
      parent_slug = row["親エリアのスラッグ"].presence
      attrs[:parent_id] = ::Area.find_by(slug: parent_slug)&.id if parent_slug
      attrs
    end
  end

  def export(records)
    AdminCsvExport.call(records, HEADERS, HEADER_TO_ATTRIBUTE) do |row, record|
      row[HEADERS.index("親エリアのスラッグ")] = record.parent&.slug
      row
    end
  end
end
