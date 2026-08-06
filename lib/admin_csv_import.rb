require "csv"

# Shared row-by-row CSV importer used by the platform admin's master-data
# screens (genres, areas, plans, member ranks). Each caller supplies the
# model class and a header-to-attribute mapping; a block can adjust the
# built attributes per row before saving (e.g. Area resolving a parent by
# slug instead of by id, which a spreadsheet can't reference directly).
module AdminCsvImport
  Result = Struct.new(:created_count, :error_rows, keyword_init: true)

  module_function

  def call(model_class, file, header_to_attribute)
    created_count = 0
    error_rows = []

    CSV.parse(strip_bom(file.read), headers: true).each_with_index do |row, index|
      attrs = header_to_attribute.each_with_object({}) { |(header, attribute), memo| memo[attribute] = row[header] }
      attrs = yield(attrs, row) if block_given?
      record = model_class.new(attrs)

      if record.save
        created_count += 1
      else
        error_rows << { line: index + 2, errors: record.errors.full_messages.join("、") }
      end
    end

    Result.new(created_count: created_count, error_rows: error_rows)
  end

  # Strips a leading UTF-8 byte-order mark, which Excel adds when saving
  # CSVs on Windows -- without this, the first header would fail to match
  # and every row would be rejected.
  def strip_bom(content)
    content = content.dup.force_encoding(Encoding::UTF_8)
    content.delete_prefix("﻿")
  end
end
