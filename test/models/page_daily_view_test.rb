require "test_helper"

class PageDailyViewTest < ActiveSupport::TestCase
  test ".record! creates a row for today and increments it on repeated calls" do
    PageDailyView.record!("index")
    PageDailyView.record!("index")

    daily = PageDailyView.find_by(page_key: "index", view_date: Date.current)
    assert_equal 2, daily.views_count
  end

  test ".record! tracks each page_key separately" do
    PageDailyView.record!("kanto")
    PageDailyView.record!("chubu")

    assert_equal 1, PageDailyView.find_by(page_key: "kanto").views_count
    assert_equal 1, PageDailyView.find_by(page_key: "chubu").views_count
  end

  test ".label_for returns the Japanese label for a known key, or the raw key otherwise" do
    assert_equal "関東ポータル", PageDailyView.label_for("kanto")
    assert_equal "架空のキー", PageDailyView.label_for("架空のキー")
  end

  test "rejects a page_key outside the known list" do
    view = PageDailyView.new(page_key: "unknown", view_date: Date.current)

    assert_not view.valid?
  end
end
