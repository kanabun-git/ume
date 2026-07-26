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

# Existing shops created before the block CMS shipped won't have picked up
# the after_create default blocks; this call is idempotent (no-ops once the
# shop already has any blocks).
shop.seed_default_page_blocks
free_text_block = shop.shop_page_blocks.find_by(block_type: :free_text)
free_text_block&.update!(settings: { "body" => "当店は新宿エリアで長年愛されるデリヘル店です。スタッフ一同、心を込めておもてなしいたします。" })

DiaryEntry.find_or_create_by!(cast: cast1, title: "本日出勤します！") do |d|
  d.body = "本日20時から出勤します。皆様にお会いできるのを楽しみにしています。"
  d.status = :published
  d.published_at = Time.current
end

Shift.find_or_create_by!(cast: cast1, work_date: Date.tomorrow) do |s|
  s.start_time = "18:00"
  s.end_time = "23:30"
  s.status = :scheduled
end

Shift.find_or_create_by!(cast: cast2, work_date: Date.tomorrow) do |s|
  s.start_time = "20:00"
  s.end_time = "23:59"
  s.status = :scheduled
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

puts "Seed data created."
puts "platform_admin: #{platform_admin.email} / password1234"
puts "shop_admin: #{shop_admin.email} / password1234"
puts "cast: #{cast1_user.email} / password1234"
