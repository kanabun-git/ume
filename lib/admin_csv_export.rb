require "csv"

# Shared row-by-row CSV exporter that pairs with AdminCsvImport, used by the
# platform admin's master-data screens (genres, areas, plans, member
# ranks). Each caller supplies the headers (in the exact order used by its
# CSV import template) and a header-to-attribute mapping; a block can fill
# in columns that aren't a direct attribute (e.g. Area exporting a parent's
# slug instead of its id, matching what the importer expects back).
module AdminCsvExport
  module_function

  def call(records, headers, header_to_attribute)
    CSV.generate do |csv|
      csv << headers
      records.each do |record|
        row = headers.map { |header| header_to_attribute[header] && record.public_send(header_to_attribute[header]) }
        row = yield(row, record) if block_given?
        csv << row
      end
    end
  end
end
