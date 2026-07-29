require "test_helper"

class ShopsControllerTest < ActionDispatch::IntegrationTest
  test "keyword filters shops by name" do
    matching = create_shop(name: "新宿サンプル店")
    create_shop(name: "池袋サンプル店")

    get shops_path(keyword: "新宿")

    assert_response :success
    assert_includes @response.body, matching.name
    assert_not_includes @response.body, "池袋サンプル店"
  end

  test "max_price filters out shops priced above the ceiling" do
    cheap = create_shop(min_price: 10_000)
    create_shop(min_price: 30_000)

    get shops_path(max_price: 15_000)

    assert_includes @response.body, cheap.name
  end

  test "cup filters to shops with at least one active cast of that cup size" do
    shop = create_shop
    create_cast(shop: shop, cup: "F")
    other_shop = create_shop

    get shops_path(cup: "F")

    assert_includes @response.body, shop.name
    assert_not_includes @response.body, other_shop.name
  end

  test "a suspended shop's detail page is not publicly reachable" do
    shop = create_shop(status: :suspended)

    get shop_path(shop)

    assert_response :not_found
  end
end
