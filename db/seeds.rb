# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

tokyo = Area.find_or_create_by!(slug: "tokyo") { |a| a.name = "東京都"; a.position = 1 }
shinjuku = Area.find_or_create_by!(slug: "shinjuku") { |a| a.name = "新宿"; a.parent = tokyo; a.position = 1 }
ikebukuro = Area.find_or_create_by!(slug: "ikebukuro") { |a| a.name = "池袋"; a.parent = tokyo; a.position = 2 }

osaka = Area.find_or_create_by!(slug: "osaka") { |a| a.name = "大阪府"; a.position = 2 }
namba = Area.find_or_create_by!(slug: "namba") { |a| a.name = "難波"; a.parent = osaka; a.position = 1 }

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

shop = Shop.find_or_create_by!(name: "サンプルデリヘル 新宿店") do |s|
  s.area = shinjuku
  s.genre = deriheru
  s.plan = standard_plan
  s.catch_copy = "新宿No.1デリヘル、業界未経験の新人多数在籍"
  s.description = "新宿エリアで人気のデリヘル店です。厳選されたキャストが多数在籍しております。"
  s.address = "東京都新宿区西新宿1-1-1"
  s.phone = "03-0000-0000"
  s.business_hours = "10:00 - 翌5:00"
  s.status = :approved
  s.view_count = 1200
end

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

cast1 = Cast.find_or_create_by!(shop: shop, name: "ゆい") do |c|
  c.user = cast1_user
  c.alias_name = "ゆいちゃん"
  c.age = 22
  c.height = 158
  c.bust = 84
  c.cup = "D"
  c.waist = 58
  c.hip = 86
  c.catch_copy = "癒し系天然キャラ"
  c.description = "お客様に癒しをお届けします。よろしくお願いします。"
  c.status = :active
end

cast2 = Cast.find_or_create_by!(shop: shop, name: "みお") do |c|
  c.alias_name = "みおちゃん"
  c.age = 25
  c.height = 162
  c.bust = 88
  c.cup = "E"
  c.waist = 59
  c.hip = 88
  c.catch_copy = "スタイル抜群のお姉さん"
  c.description = "楽しい時間を一緒に過ごしましょう。"
  c.status = :active
end

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
