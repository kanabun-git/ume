require "test_helper"

module Admin
  class CastPageBlocksControllerTest < ActionDispatch::IntegrationTest
    test "platform admin can view and reorder any shop's cast page blocks" do
      shop = create_shop
      shop.cast_page_blocks.destroy_all
      admin = create_user(role: :platform_admin)
      first = shop.cast_page_blocks.create!(block_type: :profile, layout_column: :main, position: 0)
      second = shop.cast_page_blocks.create!(block_type: :qa, layout_column: :main, position: 1)
      sign_in admin

      get admin_shop_cast_page_blocks_path(shop)
      assert_response :success

      patch move_down_admin_shop_cast_page_block_path(shop, first)

      assert_redirected_to admin_shop_cast_page_blocks_path(shop)
      assert_equal 1, first.reload.position
      assert_equal 0, second.reload.position
    end

    test "a shop admin cannot manage another shop's cast page blocks" do
      shop = create_shop
      other_shop = create_shop
      block = other_shop.cast_page_blocks.first
      shop_admin_user = create_user(role: :shop_admin, shop: shop)
      sign_in shop_admin_user

      get admin_shop_cast_page_blocks_path(other_shop)
      assert_redirected_to root_path

      patch move_down_admin_shop_cast_page_block_path(other_shop, block)
      assert_redirected_to root_path
    end

    test "toggle_hide_header flips the block's hide_header flag" do
      shop = create_shop
      shop.cast_page_blocks.destroy_all
      admin = create_user(role: :platform_admin)
      block = shop.cast_page_blocks.create!(block_type: :profile, layout_column: :main, position: 0, hide_header: false)
      sign_in admin

      patch toggle_hide_header_admin_shop_cast_page_block_path(shop, block)

      assert_redirected_to admin_shop_cast_page_blocks_path(shop)
      assert block.reload.hide_header?
    end
  end
end
