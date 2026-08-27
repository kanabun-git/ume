namespace :shop_prospects do
  desc "Split any remaining 業種/地区 genre into 業種 + a registered district for prospects saved before this existed (never deletes or otherwise modifies any prospect; safe to re-run)"
  task backfill_districts: :environment do
    count = ShopProspect.backfill_districts!
    puts "#{count}件の営業先候補の地区を設定し、ジャンルから地名を取り除きました。"
  end

  desc "Advance any 未アプローチ prospect that already has an outreach_email_sent_at to アプローチ済み, for sends made before status auto-advanced (never deletes or otherwise modifies any prospect; safe to re-run)"
  task backfill_contacted_status: :environment do
    count = ShopProspect.backfill_contacted_status!
    puts "#{count}件の営業先候補のステータスを「アプローチ済み」に更新しました。"
  end

  desc "Correct districts auto-registered with the wrong prefecture (e.g. 東京ー船橋 -> 千葉ー船橋); see ShopProspectDistrict::KNOWN_PREFECTURE_CORRECTIONS (never deletes or otherwise modifies a district; safe to re-run)"
  task fix_district_prefectures: :environment do
    corrected = ShopProspectDistrict.fix_known_prefectures!
    if corrected.empty?
      puts "修正が必要な地区はありませんでした。"
    else
      corrected.each { |name, from, to| puts "#{name}: #{from} → #{to}" }
      puts "#{corrected.size}件の地区の都道府県を修正しました。"
    end
  end
end
