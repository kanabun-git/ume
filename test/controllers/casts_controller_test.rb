require "test_helper"

class CastsControllerTest < ActionDispatch::IntegrationTest
  test "lists active casts from approved shops" do
    active_cast = create_cast(name: "在籍キャスト")
    inactive_cast = create_cast(name: "退店キャスト", status: :inactive)
    suspended_cast = create_cast(shop: create_shop(status: :suspended), name: "停止店キャスト")

    get casts_path

    assert_response :success
    assert_match active_cast.name, response.body
    assert_no_match inactive_cast.name, response.body
    assert_no_match suspended_cast.name, response.body
  end

  test "show 404s for a cast whose shop is suspended" do
    suspended_cast = create_cast(shop: create_shop(status: :suspended))

    get cast_path(suspended_cast)

    assert_response :not_found
  end

  test "viewing a cast records a daily view and increments its view count" do
    cast = create_cast

    get cast_path(cast)
    get cast_path(cast)

    assert_equal 2, cast.reload.view_count
    daily_view = CastDailyView.find_by(cast: cast, view_date: Date.current)
    assert_equal 2, daily_view.views_count
  end

  test "filters by area_id" do
    matching_area = create_area
    other_area = create_area
    matching_cast = create_cast(shop: create_shop(area: matching_area), name: "対象エリアキャスト")
    other_cast = create_cast(shop: create_shop(area: other_area), name: "対象外エリアキャスト")

    get casts_path, params: { area_id: matching_area.id }

    assert_response :success
    assert_match matching_cast.name, response.body
    assert_no_match other_cast.name, response.body
  end

  test "filters by cup size" do
    d_cup_cast = create_cast(name: "Dカップキャスト", cup: "D")
    c_cup_cast = create_cast(name: "Cカップキャスト", cup: "C")

    get casts_path, params: { cup: "D" }

    assert_response :success
    assert_match d_cup_cast.name, response.body
    assert_no_match c_cup_cast.name, response.body
  end

  test "filters by age range" do
    younger = create_cast(name: "20歳キャスト", age: 20)
    older = create_cast(name: "35歳キャスト", age: 35)

    get casts_path, params: { min_age: 25, max_age: 40 }

    assert_response :success
    assert_match older.name, response.body
    assert_no_match younger.name, response.body
  end

  test "filters by height range" do
    shorter = create_cast(name: "低身長キャスト", height: 150)
    taller = create_cast(name: "高身長キャスト", height: 170)

    get casts_path, params: { min_height: 160, max_height: 180 }

    assert_response :success
    assert_match taller.name, response.body
    assert_no_match shorter.name, response.body
  end

  test "filters to trial casts only" do
    trial_cast = create_cast(name: "体験入店キャスト", is_trial: true)
    regular_cast = create_cast(name: "通常キャスト", is_trial: false)

    get casts_path, params: { trial: "1" }

    assert_response :success
    assert_match trial_cast.name, response.body
    assert_no_match regular_cast.name, response.body
  end

  test "filters by keyword matching name or catch_copy" do
    matching_cast = create_cast(name: "未経験キャスト", catch_copy: "未経験の新人です")
    other_cast = create_cast(name: "ベテランキャスト", catch_copy: "経験豊富です")

    get casts_path, params: { keyword: "未経験" }

    assert_response :success
    assert_match matching_cast.name, response.body
    assert_no_match other_cast.name, response.body
  end
end
