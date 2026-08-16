# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Areas use find_or_initialize + update! (not find_or_create_by!) so that
# re-running db:seed backfills attributes (like `region`, added after the
# first release) onto rows that already existed from an earlier seed run.
tokyo = Area.find_or_initialize_by(slug: "tokyo")
tokyo.update!(name: "東京都", region: "関東", position: 1)
shinjuku = Area.find_or_initialize_by(slug: "shinjuku")
shinjuku.update!(name: "新宿", parent: tokyo, position: 1)
ikebukuro = Area.find_or_initialize_by(slug: "ikebukuro")
ikebukuro.update!(name: "池袋", parent: tokyo, position: 2)

kanagawa = Area.find_or_initialize_by(slug: "kanagawa")
kanagawa.update!(name: "神奈川県", region: "関東", position: 2)
yokohama = Area.find_or_initialize_by(slug: "yokohama")
yokohama.update!(name: "横浜", parent: kanagawa, position: 1)

aichi = Area.find_or_initialize_by(slug: "aichi")
aichi.update!(name: "愛知県", region: "中部", position: 3)
nagoya = Area.find_or_initialize_by(slug: "nagoya")
nagoya.update!(name: "名古屋", parent: aichi, position: 1)

osaka = Area.find_or_initialize_by(slug: "osaka")
osaka.update!(name: "大阪府", region: "関西", position: 4)
namba = Area.find_or_initialize_by(slug: "namba")
namba.update!(name: "難波", parent: osaka, position: 1)

deriheru = Genre.find_or_create_by!(slug: "deriheru") { |g| g.name = "デリヘル"; g.position = 1 }
soap = Genre.find_or_create_by!(slug: "soapland") { |g| g.name = "ソープランド"; g.position = 2 }
hoteheru = Genre.find_or_create_by!(slug: "hoteheru") { |g| g.name = "ホテヘル"; g.position = 3 }

free_plan = Plan.find_or_create_by!(name: "フリープラン") { |p| p.monthly_fee = 0; p.priority_weight = 1; p.position = 1 }
standard_plan = Plan.find_or_create_by!(name: "スタンダードプラン") { |p| p.monthly_fee = 30_000; p.priority_weight = 3; p.position = 2 }
premium_plan = Plan.find_or_create_by!(name: "プレミアムプラン") { |p| p.monthly_fee = 80_000; p.priority_weight = 8; p.position = 3 }

platform_admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.name = "運営管理者"
  u.role = :platform_admin
  u.password = "password1234"
  u.password_confirmation = "password1234"
end

shop = Shop.find_or_initialize_by(name: "サンプルデリヘル 新宿店")
shop.assign_attributes(
  area: shinjuku,
  genre: deriheru,
  plan: standard_plan,
  chain_name: "UH系列",
  catch_copy: "新宿No.1デリヘル、業界未経験の新人多数在籍",
  description: "新宿エリアで人気のデリヘル店です。厳選されたキャストが多数在籍しております。",
  address: "東京都新宿区西新宿1-1-1",
  phone: "03-0000-0000",
  business_hours: "10:00 - 翌5:00",
  status: :approved,
  view_count: 1200,
  price_note: "60分12000円〜",
  min_price: 12_000,
  transportation_fee_note: "0〜1000円",
  coverage_area_note: "新宿駅発着、代々木、高田馬場、中野",
  online_reservation: true,
  visit_point_program: true,
  coupon_available: true,
  coupon_description: "【ネット予約限定】オキニ探しコース 60分11000円",
  event_ongoing: true,
  recruiting_cast: true,
  recruiting_staff: false,
  recruiting_message: "未経験大歓迎!日給保証あり、まずはお気軽にご応募ください。",
  time_display_format: :extended,
  editor_review: "新宿を中心に展開する人気店。厳選されたキャストと丁寧な接客で高い評価を得ている。"
)
shop.save!

ShopSubscription.find_or_create_by!(shop: shop, plan: standard_plan) do |sub|
  sub.started_on = 1.month.ago.to_date
  sub.status = :active
end

shop_admin = User.find_or_create_by!(email: "shop_admin@example.com") do |u|
  u.name = "サンプルデリヘル 店長"
  u.role = :shop_admin
  u.shop = shop
  u.password = "password1234"
  u.password_confirmation = "password1234"
end

cast1_user = User.find_or_create_by!(email: "cast1@example.com") do |u|
  u.name = "ゆい"
  u.role = :cast
  u.shop = shop
  u.password = "password1234"
  u.password_confirmation = "password1234"
end

cast1 = Cast.find_or_initialize_by(shop: shop, name: "ゆい")
cast1.assign_attributes(
  user: cast1_user,
  alias_name: "ゆいちゃん",
  age: 22,
  height: 158,
  bust: 84,
  cup: "D",
  waist: 58,
  hip: 86,
  catch_copy: "癒し系天然キャラ",
  description: "お客様に癒しをお届けします。よろしくお願いします。",
  status: :active,
  manager_recommended: true,
  pick_up: true,
  zodiac_sign: "おうし座",
  blood_type: "A型",
  appeal_comment: "皆様に癒しの時間をお届けできるよう頑張ります!",
  selling_points: "天然な性格と柔らかい物腰が好評です。",
  qa_message: "お休みの日は? → 読書とカフェ巡りが好きです。"
)
cast1.save!

cast2 = Cast.find_or_initialize_by(shop: shop, name: "みお")
cast2.assign_attributes(
  alias_name: "みおちゃん",
  age: 25,
  height: 162,
  bust: 88,
  cup: "E",
  waist: 59,
  hip: 88,
  catch_copy: "スタイル抜群のお姉さん",
  description: "楽しい時間を一緒に過ごしましょう。",
  status: :active,
  is_trial: true,
  pick_up: true,
  zodiac_sign: "さそり座",
  blood_type: "B型",
  appeal_comment: "明るく楽しい時間をお約束します!",
  selling_points: "抜群のスタイルと大人の色気が自慢です。",
  qa_message: "好きな食べ物は? → 甘いものが大好きです。"
)
cast2.save!

# Simple procedurally-generated placeholder avatars (a plain color gradient)
# so every sample cast has a "photo" without using any real person's
# likeness. Rendered as a real PNG (via chunky_png, pure Ruby, no
# ImageMagick/libvips binary needed) since ActiveStorage does not serve
# SVG blobs inline by default (they're treated as downloads, a built-in
# XSS safeguard) and would show up as broken images in <img> tags.
def placeholder_avatar_png(hex_color)
  width, height = 300, 400
  base = ChunkyPNG::Color.from_hex(hex_color)
  r, g, b = ChunkyPNG::Color.r(base), ChunkyPNG::Color.g(base), ChunkyPNG::Color.b(base)
  image = ChunkyPNG::Image.new(width, height, base)
  height.times do |y|
    shade = 1.0 - (0.25 * (y / height.to_f))
    row_color = ChunkyPNG::Color.rgb((r * shade).round, (g * shade).round, (b * shade).round)
    image.line(0, y, width - 1, y, row_color)
  end
  image.to_blob
end

def attach_placeholder_photo(cast, color)
  return if cast.photos.attached?

  cast.photos.attach(
    io: StringIO.new(placeholder_avatar_png(color)),
    filename: "#{cast.name}.png",
    content_type: "image/png"
  )
end

attach_placeholder_photo(cast1, "#e8768f")
attach_placeholder_photo(cast2, "#c76b9c")

# Additional sample casts (総勢10名になるよう追加) so listing/ranking/pickup
# UIも実データに近い状態で確認できるようにする。
additional_casts = [
  { name: "さくら", alias_name: "さくらちゃん", age: 21, height: 156, bust: 83, cup: "C", waist: 56, hip: 84,
    catch_copy: "笑顔が可愛いアイドル系", zodiac_sign: "ふたご座", blood_type: "O型", pick_up: true, color: "#e0729a" },
  { name: "りお", alias_name: "りおちゃん", age: 24, height: 160, bust: 86, cup: "D", waist: 57, hip: 87,
    catch_copy: "クールビューティー", zodiac_sign: "みずがめ座", blood_type: "AB型", manager_recommended: true, color: "#9a6bc4" },
  { name: "こはる", alias_name: "こはるちゃん", age: 20, height: 154, bust: 81, cup: "C", waist: 55, hip: 83,
    catch_copy: "新人!元気いっぱい系", zodiac_sign: "おひつじ座", blood_type: "A型", is_trial: true, color: "#e2a13f" },
  { name: "あかり", alias_name: "あかりちゃん", age: 27, height: 163, bust: 90, cup: "F", waist: 60, hip: 90,
    catch_copy: "包容力抜群のお姉さん", zodiac_sign: "しし座", blood_type: "B型", pick_up: true, color: "#c94f4f" },
  { name: "めい", alias_name: "めいちゃん", age: 23, height: 159, bust: 85, cup: "D", waist: 58, hip: 86,
    catch_copy: "甘えん坊な妹系", zodiac_sign: "かに座", blood_type: "O型", color: "#4f9bc9" },
  { name: "りん", alias_name: "りんちゃん", age: 26, height: 161, bust: 87, cup: "E", waist: 59, hip: 88,
    catch_copy: "上品な清楚系美人", zodiac_sign: "てんびん座", blood_type: "A型", color: "#5fa878" },
  { name: "かのん", alias_name: "かのんちゃん", age: 22, height: 157, bust: 82, cup: "C", waist: 56, hip: 85,
    catch_copy: "小悪魔テクニシャン", zodiac_sign: "さそり座", blood_type: "B型", color: "#b06bc9" },
  { name: "ののか", alias_name: "ののかちゃん", age: 25, height: 158, bust: 89, cup: "F", waist: 58, hip: 89,
    catch_copy: "グラマラスな人気No.1", zodiac_sign: "やぎ座", blood_type: "O型", pick_up: true, color: "#d97b3f" }
]

additional_casts.each do |attrs|
  color = attrs.delete(:color)
  cast = Cast.find_or_initialize_by(shop: shop, name: attrs[:name])
  cast.assign_attributes(attrs.merge(status: :active))
  cast.save!
  attach_placeholder_photo(cast, color)
end

# Existing shops created before the block CMS shipped won't have picked up
# the after_create default blocks; these calls are idempotent (no-op once
# the shop already has any blocks of that kind).
shop.seed_default_page_blocks
free_text_block = shop.shop_page_blocks.find_by(block_type: :free_text)
free_text_block&.update!(settings: { "body" => "当店は新宿エリアで長年愛されるデリヘル店です。スタッフ一同、心を込めておもてなしいたします。" })

# price_table blocks are optional (not part of seed_default_page_blocks) and
# admin-composed: each is titled freely and holds free-form label/value rows,
# demonstrating a price table and a per-area transportation fee table.
{
  "料金表" => [
    { "label" => "60分", "value" => "12,000円" },
    { "label" => "90分", "value" => "17,000円" },
    { "label" => "120分", "value" => "22,000円" }
  ],
  "交通費" => [
    { "label" => "新宿区内", "value" => "1,000円" },
    { "label" => "中野区・杉並区", "value" => "2,000円" }
  ]
}.each_with_index do |(title, rows), index|
  block = shop.shop_page_blocks.find_or_initialize_by(block_type: :price_table, title: title)
  block.assign_attributes(position: shop.shop_page_blocks.maximum(:position).to_i + index + 1, settings: { "rows" => rows })
  block.save!
end

shop.seed_default_cast_page_blocks

DiaryEntry.find_or_create_by!(cast: cast1, title: "本日出勤します！") do |d|
  d.body = "本日20時から出勤します。皆様にお会いできるのを楽しみにしています。"
  d.status = :published
  d.published_at = Time.current
end

# A fuller shift spread across the week so the "週間出勤予定" block (日付
# タブ + 横5名グリッド) has enough data to demonstrate tab switching and
# row wrapping past 5 people. The last few entries end after midnight so the
# 日またぎ handling and the 26:00-style display are exercised too.
all_casts = [cast1, cast2] + additional_casts.map { |attrs| Cast.find_by(shop: shop, name: attrs[:name]) }
shift_times = [
  ["12:00", "17:00", false], ["12:00", "20:00", false], ["13:00", "18:00", false],
  ["14:00", "22:00", false], ["15:00", "20:00", false], ["16:00", "23:00", false],
  ["17:00", "22:00", false], ["18:00", "23:30", false],
  ["19:00", "01:00", true],  ["20:00", "02:00", true]
]
[0, 1, 2].each do |day_offset|
  work_date = Date.current + day_offset
  casts_today = day_offset.zero? ? all_casts : all_casts.first((all_casts.size * 0.6).round)
  casts_today.each_with_index do |cast, i|
    start_time, end_time, ends_next_day = shift_times[i % shift_times.size]
    # find_or_initialize + save! (not find_or_create_by!) so re-running
    # db:seed backfills columns added later, like ends_next_day, onto rows
    # that already exist from an earlier run.
    shift = Shift.find_or_initialize_by(cast: cast, work_date: work_date)
    shift.assign_attributes(
      start_time: start_time,
      end_time: end_time,
      ends_next_day: ends_next_day,
      status: :scheduled
    )
    shift.save!
  end
end

Review.find_or_create_by!(shop: shop, cast: cast1, reviewer_name: "利用者A") do |r|
  r.rating = 5
  r.body = "とても丁寧な対応で癒されました。また利用したいです。"
  r.status = :approved
end

Review.find_or_create_by!(shop: shop, reviewer_name: "利用者B") do |r|
  r.rating = 3
  r.body = "普通でした。"
  r.status = :pending
end

Coupon.find_or_create_by!(shop: shop, title: "【WEB予約限定】フリー割") do |c|
  c.coupon_number = "A-101"
  c.cast = cast1
  c.course_name = "45分コース"
  c.regular_price = 20000
  c.discounted_price = 14000
  c.valid_from = Date.current - 30
  c.conditions = "ご新規様は別途入会金2000円頂戴しております。\n曜日や時間帯によって金額に変動がございます。"
  c.net_reservation_only = true
end

Coupon.find_or_create_by!(shop: shop, title: "新人割引60分クーポン!") do |c|
  c.coupon_number = "A-102"
  c.course_name = "60分コース"
  c.regular_price = 12500
  c.discounted_price = 10500
  c.valid_from = Date.current - 5
  c.conditions = "入店間もない新人さんをご指名頂きますと最大2,000円値引きいたします!"
end

MemberRank.find_or_create_by!(min_approved_count: 1) { |r| r.name = "ブロンズ会員" }
MemberRank.find_or_create_by!(min_approved_count: 5) { |r| r.name = "シルバー会員" }
MemberRank.find_or_create_by!(min_approved_count: 20) { |r| r.name = "ゴールド会員" }

regular_rank = ShopMemberRank.find_or_create_by!(shop: shop, min_visit_count: 3) { |r| r.name = "レギュラー会員" }
ShopMemberBenefit.find_or_create_by!(shop_member_rank: regular_rank, name: "500円割引券") do |b|
  b.benefit_type = :discount_ticket
  b.description = "次回来店時のご利用料金から500円引きになります。"
end

gold_rank = ShopMemberRank.find_or_create_by!(shop: shop, min_visit_count: 10) { |r| r.name = "ゴールド会員" }
ShopMemberBenefit.find_or_create_by!(shop_member_rank: gold_rank, name: "指名料無料券") do |b|
  b.benefit_type = :free_ticket
  b.description = "次回ご指名時の指名料が無料になります。"
end

# Records enough visits to reach (but not duplicate past) `target_count`,
# so re-running db:seed doesn't keep piling on more visits/points/benefits
# each time.
def ensure_shop_visits(membership, target_count)
  (target_count - membership.visit_count).times do
    membership.record_visit!(visited_on: Date.current, points_earned: 100, memo: "来店")
  end
end

# Three individual members (個人会員) at different points on both rank
# ladders -- the site-wide MemberRank (driven by approved review count)
# and this shop's own ShopMemberRank (driven by visit count) -- so admin
# screens have realistic-looking members to browse instead of empty lists.
dummy_member1 = Member.find_or_create_by!(email: "member.gold@example.com") do |m|
  m.name = "モデル太郎"
  m.password = "password1234"
  m.password_confirmation = "password1234"
  m.phone_number = "09011112222"
  m.phone_verified_at = Time.current
end
25.times { |i| Review.find_or_create_by!(shop: shop, member: dummy_member1, reviewer_name: dummy_member1.name, body: "とても満足しています。また利用したいです。(#{i + 1})") { |r| r.rating = 5; r.status = :approved } }
ensure_shop_visits(ShopMembership.find_or_create_by!(shop: shop, member: dummy_member1), 12)

dummy_member2 = Member.find_or_create_by!(email: "member.silver@example.com") do |m|
  m.name = "モデル花子"
  m.password = "password1234"
  m.password_confirmation = "password1234"
  m.phone_number = "09033334444"
  m.phone_verified_at = Time.current
end
6.times { |i| Review.find_or_create_by!(shop: shop, member: dummy_member2, reviewer_name: dummy_member2.name, body: "接客が丁寧で良かったです。(#{i + 1})") { |r| r.rating = 4; r.status = :approved } }
ensure_shop_visits(ShopMembership.find_or_create_by!(shop: shop, member: dummy_member2), 4)

dummy_member3 = Member.find_or_create_by!(email: "member.bronze@example.com") do |m|
  m.name = "モデル次郎"
  m.password = "password1234"
  m.password_confirmation = "password1234"
end
2.times { |i| Review.find_or_create_by!(shop: shop, member: dummy_member3, reviewer_name: dummy_member3.name, body: "また利用します。(#{i + 1})") { |r| r.rating = 3; r.status = :approved } }
ensure_shop_visits(ShopMembership.find_or_create_by!(shop: shop, member: dummy_member3), 1)

# メールアドレス管理画面(/mailadmin)が管理する3サイト。4サイト目以降は
# 画面から登録できるので、ここにあるのは運用中の3つだけ。アドレスは
# パスワードを伴うため種は撒かず、必ず画面から登録する。
[
  ["fuzoku-zero.com", "FuzokuZero", "風俗店ポータルサイト。"],
  ["kanabun.tech", "kanabun.tech", "メールアドレス管理画面(/mailadmin)を置いているサイト。"],
  ["puremint.jp", "PureMint", nil]
].each do |domain, name, note|
  MailDomain.find_or_initialize_by(domain: domain).update!(name: name, note: note)
end

puts "Seed data created."
puts "platform_admin: #{platform_admin.email} / password1234"
puts "shop_admin: #{shop_admin.email} / password1234"
puts "cast: #{cast1_user.email} / password1234"
puts "member (ゴールド会員/店舗ゴールド会員): #{dummy_member1.email} / password1234"
puts "member (シルバー会員/店舗レギュラー会員): #{dummy_member2.email} / password1234"
puts "member (ブロンズ会員/店舗未認定・SMS未認証): #{dummy_member3.email} / password1234"
