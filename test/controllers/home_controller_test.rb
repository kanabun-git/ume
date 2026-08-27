require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "kanto page only shows shops from the kanto region" do
    kanto_area = create_area(region: "関東")
    chubu_area = create_area(region: "中部")
    kanto_shop = create_shop(area: kanto_area, name: "カントウ店舗")
    chubu_shop = create_shop(area: chubu_area, name: "チュウブ店舗")

    get kanto_home_path

    assert_response :success
    assert_match kanto_shop.name, response.body
    assert_no_match chubu_shop.name, response.body
  end

  test "chubu page only shows shops from the chubu region" do
    kanto_area = create_area(region: "関東")
    chubu_area = create_area(region: "中部")
    kanto_shop = create_shop(area: kanto_area, name: "カントウ店舗2")
    chubu_shop = create_shop(area: chubu_area, name: "チュウブ店舗2")

    get chubu_home_path

    assert_response :success
    assert_match chubu_shop.name, response.body
    assert_no_match kanto_shop.name, response.body
  end

  test "a shop under a child area is filtered by its parent prefecture's region" do
    parent = create_area(region: "中部")
    child = create_area(parent: parent)
    shop = create_shop(area: child, name: "シティ店舗")

    get chubu_home_path
    assert_match shop.name, response.body

    get kanto_home_path
    assert_no_match shop.name, response.body
  end

  test "an unrecognized region param falls back to the first active region" do
    get kanto_home_path(region: "bogus")

    assert_response :success
  end

  test "visiting the kanto portal records a kanto page view for analytics" do
    assert_difference -> { PageDailyView.where(page_key: "kanto").sum(:views_count) }, 1 do
      get kanto_home_path
    end
  end

  test "visiting the chubu portal records a chubu page view for analytics" do
    assert_difference -> { PageDailyView.where(page_key: "chubu").sum(:views_count) }, 1 do
      get chubu_home_path
    end
  end

  test "today's shift preview is filtered to the current region" do
    kanto_area = create_area(region: "関東")
    chubu_area = create_area(region: "中部")
    kanto_cast = create_cast(shop: create_shop(area: kanto_area), name: "カントウ出勤キャスト")
    chubu_cast = create_cast(shop: create_shop(area: chubu_area), name: "チュウブ出勤キャスト")
    kanto_cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")
    chubu_cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")

    get kanto_home_path

    assert_match kanto_cast.name, response.body
    assert_no_match chubu_cast.name, response.body
  end

  test "coupon preview is filtered to the current region" do
    kanto_area = create_area(region: "関東")
    chubu_area = create_area(region: "中部")
    kanto_shop = create_shop(area: kanto_area, name: "カントウクーポン店舗")
    chubu_shop = create_shop(area: chubu_area, name: "チュウブクーポン店舗")
    kanto_shop.coupons.create!(title: "カントウクーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: 1.day.ago.to_date)
    chubu_shop.coupons.create!(title: "チュウブクーポン", course_name: "60分", regular_price: 20000, discounted_price: 14000, valid_from: 1.day.ago.to_date)

    get kanto_home_path

    assert_match kanto_shop.name, response.body
    assert_no_match chubu_shop.name, response.body
  end

  test "latest diary entries exclude a diary entry whose shop is suspended" do
    suspended_shop = create_shop(status: :suspended)
    suspended_cast = create_cast(shop: suspended_shop, name: "停止店キャスト")
    hidden_entry = create_diary_entry(cast: suspended_cast, title: "停止店の日記")

    visible_cast = create_cast(name: "公開店キャスト")
    visible_entry = create_diary_entry(cast: visible_cast, title: "公開店の日記")

    get kanto_home_path

    assert_response :success
    assert_match visible_entry.title, response.body
    assert_no_match hidden_entry.title, response.body
  end

  test "today's shift preview excludes a shift whose shop is suspended" do
    suspended_shop = create_shop(status: :suspended)
    suspended_cast = create_cast(shop: suspended_shop, name: "停止店出勤キャスト")
    suspended_cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")

    get kanto_home_path

    assert_response :success
    assert_no_match suspended_cast.name, response.body
  end

  test "shows an empty-state message when there are no diary entries for the region" do
    get kanto_home_path

    assert_response :success
    assert_match "まだ日記がありません", response.body
  end

  test "does not show the diary empty-state message when an entry exists" do
    entry = create_diary_entry(cast: create_cast(name: "日記ありキャスト"))

    get kanto_home_path

    assert_response :success
    assert_match entry.title, response.body
    assert_no_match "まだ日記がありません", response.body
  end

  test "video preview renders a 5-wide thumbnail grid" do
    shop = create_shop
    shop.shop_page_blocks.create!(
      block_type: :movie, position: 0, visible: true,
      settings: { "video_url" => "https://www.youtube.com/embed/dQw4w9WgXcQ" }
    )

    get kanto_home_path

    assert_response :success
    assert_select ".video-thumb-grid .video-thumb", 1
  end
end
