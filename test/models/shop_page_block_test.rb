require "test_helper"

class ShopPageBlockTest < ActiveSupport::TestCase
  test "label falls back to the block type's default when title is blank" do
    block = create_shop.shop_page_blocks.create!(block_type: :coupon, position: 0)

    assert_equal "クーポン", block.label
  end

  test "label prefers an explicit title over the block type default" do
    block = create_shop.shop_page_blocks.create!(block_type: :coupon, title: "本日限定クーポン", position: 0)

    assert_equal "本日限定クーポン", block.label
  end

  # Regression test: the price_table admin form submits settings[rows] with
  # numeric indices, and removing a middle row leaves a gap (e.g. "1", "2"
  # instead of "0", "1"). Rails then parses that as a Hash rather than an
  # Array, which broke public rendering (see shops/blocks/_price_table.html.erb)
  # until ShopPageBlock#normalize_settings_rows was added.
  test "normalizes a gapped hash of settings[rows] back into a plain array" do
    block = create_shop.shop_page_blocks.create!(
      block_type: :price_table,
      position: 0,
      settings: { "rows" => { "1" => { "label" => "延長30分", "value" => "5,000円" }, "2" => { "label" => "VIP", "value" => "20,000円" } } }
    )

    assert_kind_of Array, block.settings["rows"]
    assert_equal [
      { "label" => "延長30分", "value" => "5,000円" },
      { "label" => "VIP", "value" => "20,000円" }
    ], block.settings["rows"]
  end

  test "leaves settings[rows] untouched when it is already an array" do
    rows = [{ "label" => "60分", "value" => "12,000円" }]
    block = create_shop.shop_page_blocks.create!(block_type: :price_table, position: 0, settings: { "rows" => rows })

    assert_equal rows, block.settings["rows"]
  end
end
