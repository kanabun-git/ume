# A district (e.g. "錦糸町") pulled out of ShopProspect#genre's trailing
# "業種/地区" segment (see ShopProspect#sync_shop_prospect_district) and
# auto-registered the first time it's seen. prefecture defaults to "東京"
# since every listing exported so far only covers Tokyo -- an admin can
# correct it per district via 営業先候補管理 > 地区管理 once other
# prefectures start showing up.
class ShopProspectDistrict < ApplicationRecord
  has_many :shop_prospects

  validates :name, presence: true, uniqueness: true
  validates :prefecture, presence: true

  default_scope { order(:prefecture, :name) }

  def display_name
    "#{prefecture}ー#{name}"
  end

  # Districts whose name defaulted to "東京" on auto-registration but are
  # actually in a neighboring prefecture (e.g. "船橋" is in 千葉, not 東京;
  # "太田"/"高崎"/"伊勢崎" are in 群馬 -- distinct from Tokyo's 大田区). Keyed
  # by the exact district name; values are the correct prefecture. Checked
  # against the full set of districts registered as of 2026-08-28 -- a
  # newly-imported district name not in this list still defaults to 東京
  # and needs the same manual correction (地区管理) or an addition here.
  KNOWN_PREFECTURE_CORRECTIONS = {
    "伊勢崎" => "群馬",
    "佐野・足利" => "栃木",
    "千葉市・幕張" => "千葉",
    "君津・木更津・東金" => "千葉",
    "土浦・取手・つくば" => "茨城",
    "大宮・さいたま・浦和" => "埼玉",
    "太田" => "群馬",
    "宇都宮市" => "栃木",
    "小山・下野" => "栃木",
    "川口・西川口" => "埼玉",
    "川越・鶴ヶ島・坂戸" => "埼玉",
    "市原・茂原" => "千葉",
    "成田・富里・旭" => "千葉",
    "所沢・入間・狭山" => "埼玉",
    "本庄" => "埼玉",
    "松戸" => "千葉",
    "栄町" => "千葉",
    "水戸・笠間・那珂・ひたちなか" => "茨城",
    "熊谷・行田・鴻巣・東松山" => "埼玉",
    "神栖・鹿嶋" => "茨城",
    "船橋" => "千葉",
    "西船橋" => "千葉",
    "越谷・草加・三郷" => "埼玉",
    "那須・黒磯" => "栃木",
    "高崎" => "群馬",
    # 中部ポータル(愛知・岐阜・静岡・長野・山梨・新潟・石川・福井)向けに
    # 登録された地区が、関東中心の初期データと同じくすべて東京にデフォルト
    # されてしまっていたもの(2026-08-28、営業先候補管理からの報告で発覚)。
    "一宮・稲沢" => "愛知",
    "三島・熱海・伊豆" => "静岡",
    "三条市" => "新潟",
    "上田市" => "長野",
    "上越市" => "新潟",
    "中巨摩郡昭和町" => "山梨",
    "今池・池下・千種区" => "愛知",
    "佐久市" => "長野",
    "刈谷・知立・大府" => "愛知",
    "加賀市片山津" => "石川",
    "半田・知多・東海市方面" => "愛知",
    "可児・多治見・高山・中津川" => "岐阜",
    "名古屋駅・中村・西区" => "愛知",
    "大垣市・羽島市" => "岐阜",
    "大曽根・北区" => "愛知",
    "安城" => "愛知",
    "富士・御殿場" => "静岡",
    "岐南町・各務原市" => "岐阜",
    "岐阜市内" => "岐阜",
    "岡崎" => "愛知",
    "島田・吉田" => "静岡",
    "新栄・東新町・中区" => "愛知",
    "新潟市" => "新潟",
    "春日井・小牧・尾張旭" => "愛知",
    "松本市" => "長野",
    "柴田・南区・港区" => "愛知",
    "栄・大須・中区" => "愛知",
    "沼津市" => "静岡",
    "浜松市" => "静岡",
    "焼津・藤枝" => "静岡",
    "瑞穂区・昭和区" => "愛知",
    "甲府市" => "山梨",
    "福井市" => "福井",
    "笛吹市" => "山梨",
    "納屋橋・中村区" => "愛知",
    "菊川・御前崎・牧之原" => "静岡",
    "豊橋・豊川" => "愛知",
    "豊田" => "愛知",
    "金山・熱田区・中川区" => "愛知",
    "金沢市" => "石川",
    "金津園" => "岐阜",
    "錦・丸の内・中区" => "愛知",
    "長岡市" => "新潟",
    "長野市" => "長野",
    "静岡市" => "静岡"
  }.freeze

  # Used by ShopProspect#sync_shop_prospect_district / .backfill_districts!
  # instead of a bare find_or_create_by!(name:) -- registering a brand-new
  # district with a name already in KNOWN_PREFECTURE_CORRECTIONS (e.g.
  # "船橋") sets its prefecture correctly right away, instead of defaulting
  # to 東京 and needing another fix_known_prefectures! run later. A name not
  # in the list still defaults to 東京 as before.
  def self.find_or_register(name)
    find_or_create_by!(name: name) do |district|
      known_prefecture = KNOWN_PREFECTURE_CORRECTIONS[name]
      district.prefecture = known_prefecture if known_prefecture
    end
  end

  # One-off correction for districts auto-registered with the wrong
  # prefecture (see KNOWN_PREFECTURE_CORRECTIONS). Only touches rows whose
  # prefecture is still wrong, so it's safe to re-run; never creates,
  # deletes, or otherwise modifies a district. Returns the corrected
  # [name, from, to] triples for the caller to report.
  def self.fix_known_prefectures!
    corrected = []

    KNOWN_PREFECTURE_CORRECTIONS.each do |name, correct_prefecture|
      district = find_by(name: name)
      next unless district
      next if district.prefecture == correct_prefecture

      from = district.prefecture
      district.update!(prefecture: correct_prefecture)
      corrected << [name, from, correct_prefecture]
    end

    corrected
  end
end
