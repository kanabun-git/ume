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
end
