module RegionMapHelper
  # Percentage-based click zones over the illustrated map images
  # (app/assets/images/{kanto,tyubu}_pop_map.png), roughly centered on each
  # prefecture's label so the hit area tracks the image at any render size.
  # [top%, left%, width%, height%]
  IMAGE_MAP_ZONES = {
    "関東" => {
      image: "kanto_pop_map.png",
      alt: "関東地方の地図",
      zones: {
        "群馬県"   => [19, 19, 22, 14],
        "栃木県"   => [16, 45, 22, 14],
        "茨城県"   => [33, 57, 22, 14],
        "埼玉県"   => [40, 31, 22, 14],
        "東京都"   => [54, 33, 22, 14],
        "神奈川県" => [67, 29, 22, 14],
        "千葉県"   => [69, 52, 22, 14]
      }
    },
    "中部" => {
      image: "tyubu_pop_map.png",
      alt: "中部地方の地図",
      zones: {
        "新潟県" => [21, 70, 22, 14],
        "富山県" => [23, 32, 22, 14],
        "石川県" => [24, 14, 22, 14],
        "福井県" => [35, 11, 22, 14],
        "長野県" => [44, 41, 22, 14],
        "岐阜県" => [44, 22, 22, 14],
        "山梨県" => [60, 47, 22, 14],
        "愛知県" => [61, 19, 22, 14],
        "静岡県" => [75, 33, 22, 14]
      }
    }
  }.freeze

  def image_map_for(region)
    IMAGE_MAP_ZONES.fetch(region, { image: nil, alt: "", zones: {} })
  end
end
