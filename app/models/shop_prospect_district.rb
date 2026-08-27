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
  # against the full set of districts registered as of 2026-08-27 -- a
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
    "高崎" => "群馬"
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
