namespace :shop_prospects do
  desc "Fill in shop_prospect_district for prospects saved before the district feature existed (never deletes or otherwise modifies any prospect; safe to re-run)"
  task backfill_districts: :environment do
    count = ShopProspect.backfill_districts!
    puts "#{count}件の営業先候補に地区を設定しました。"
  end
end
