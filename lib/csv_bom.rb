# Prepends the UTF-8 byte-order mark that Excel needs to correctly detect a
# downloaded CSV's encoding on Windows -- without it, Excel guesses
# Shift-JIS and every Japanese header/cell renders as mojibake when opened
# directly (e.g. "キャスト名" showing as "繧ｭ繝｣繧ｹ繝亥錐"). A CSV a user
# re-uploads with this BOM already round-trips fine -- each importer's
# strip_bom strips it back off before parsing.
module CsvBom
  MARK = "﻿".freeze

  module_function

  def wrap(csv_string)
    MARK + csv_string
  end
end
