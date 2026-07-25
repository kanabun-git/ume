module RegionMapHelper
  # Rough schematic (not geographically precise) grid coordinates for each
  # prefecture, used to lay out an original CSS-grid "map" per region.
  # [row, column], 1-indexed.
  PREFECTURE_GRID = {
    "関東" => {
      "群馬県" => [1, 1], "栃木県" => [1, 2], "茨城県" => [1, 3],
      "埼玉県" => [2, 1],                     "千葉県" => [2, 3],
      "東京都" => [3, 1],
      "神奈川県" => [4, 1],
    },
    "中部" => {
      "新潟県" => [1, 2],
      "富山県" => [2, 1], "長野県" => [2, 2],
      "石川県" => [3, 1], "岐阜県" => [3, 2], "山梨県" => [3, 3],
      "福井県" => [4, 1],                     "静岡県" => [4, 3],
      "愛知県" => [5, 2],
    },
  }.freeze

  def region_map_grid(region)
    PREFECTURE_GRID.fetch(region, {})
  end
end
