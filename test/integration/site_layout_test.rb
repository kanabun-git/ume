require "test_helper"

class SiteLayoutTest < ActionDispatch::IntegrationTest
  test "the header shows a keyword search box and the primary nav links" do
    get shops_path

    assert_select "form.site-header-search input[name=?]", "keyword"
    assert_select "nav.site-header-nav a", text: "店舗一覧"
    assert_select "nav.site-header-nav a", text: "女の子検索"
  end

  test "the header's prefecture bar links to the active regions' prefectures" do
    area = create_area(region: "関東")

    get shops_path

    assert_select "div.site-header-prefectures a[href=?]", area_path(area), text: area.name
  end

  test "the footer lists active regions with prefecture links and marks inactive regions as coming soon" do
    area = create_area(region: "関東")

    get shops_path

    assert_select "footer.site-footer a[href=?]", area_path(area), text: area.name
    assert_select "footer.site-footer", text: /北海道.*準備中/m
  end

  test "the footer includes a copyright line" do
    get shops_path

    assert_match "FuzokuZero", css_select("p.site-footer-copyright").text
  end
end
