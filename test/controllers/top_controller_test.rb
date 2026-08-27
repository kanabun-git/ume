require "test_helper"

class TopControllerTest < ActionDispatch::IntegrationTest
  test "root shows the region-picker gate page with links to both regions" do
    get root_path

    assert_response :success
    assert_select "a[href=?]", kanto_home_path
    assert_select "a[href=?]", chubu_home_path
  end

  test "gate page links under-18 visitors offsite" do
    get root_path

    assert_response :success
    assert_select "a.top-gate-age-link[href=?]", "https://www.google.com/"
  end

  test "visiting the gate page records a page view for analytics" do
    assert_difference -> { PageDailyView.where(page_key: "index").sum(:views_count) }, 1 do
      get root_path
    end
  end
end
