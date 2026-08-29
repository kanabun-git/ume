require "test_helper"

module ShopAdmin
  class CastPageBlocksControllerTest < ActionDispatch::IntegrationTest
    test "move_up swaps position with the previous block in the same column" do
      shop = create_shop
      shop.cast_page_blocks.destroy_all # clear the blocks auto-seeded on shop creation
      user = create_user(role: :shop_admin, shop: shop)
      first = shop.cast_page_blocks.create!(block_type: :profile, layout_column: :main, position: 0)
      second = shop.cast_page_blocks.create!(block_type: :qa, layout_column: :main, position: 1)
      sign_in user

      patch move_up_shop_admin_cast_page_block_path(second)

      assert_redirected_to shop_admin_cast_page_blocks_path
      assert_equal 0, second.reload.position
      assert_equal 1, first.reload.position
    end

    # See the equivalent ShopPageBlock test for why a 3-item list (not 2)
    # is needed to catch a "swaps with the wrong block" ordering regression.
    test "move_up on the last of three blocks swaps with its immediate neighbor, not the first block" do
      shop = create_shop
      shop.cast_page_blocks.destroy_all
      user = create_user(role: :shop_admin, shop: shop)
      first = shop.cast_page_blocks.create!(block_type: :profile, layout_column: :main, position: 0)
      second = shop.cast_page_blocks.create!(block_type: :qa, layout_column: :main, position: 1)
      third = shop.cast_page_blocks.create!(block_type: :shift, layout_column: :main, position: 2)
      sign_in user

      patch move_up_shop_admin_cast_page_block_path(third)

      assert_redirected_to shop_admin_cast_page_blocks_path
      assert_equal 0, first.reload.position
      assert_equal 2, second.reload.position
      assert_equal 1, third.reload.position
    end

    test "move_down swaps position with the next block in the same column" do
      shop = create_shop
      shop.cast_page_blocks.destroy_all
      user = create_user(role: :shop_admin, shop: shop)
      first = shop.cast_page_blocks.create!(block_type: :profile, layout_column: :main, position: 0)
      second = shop.cast_page_blocks.create!(block_type: :qa, layout_column: :main, position: 1)
      sign_in user

      patch move_down_shop_admin_cast_page_block_path(first)

      assert_redirected_to shop_admin_cast_page_blocks_path
      assert_equal 1, first.reload.position
      assert_equal 0, second.reload.position
    end

    test "toggle_visibility flips the block's visible flag" do
      shop = create_shop
      shop.cast_page_blocks.destroy_all
      user = create_user(role: :shop_admin, shop: shop)
      block = shop.cast_page_blocks.create!(block_type: :profile, layout_column: :main, position: 0, visible: true)
      sign_in user

      patch toggle_visibility_shop_admin_cast_page_block_path(block)

      assert_redirected_to shop_admin_cast_page_blocks_path
      assert_not block.reload.visible?
    end

    test "toggle_hide_header flips the block's hide_header flag" do
      shop = create_shop
      shop.cast_page_blocks.destroy_all
      user = create_user(role: :shop_admin, shop: shop)
      block = shop.cast_page_blocks.create!(block_type: :profile, layout_column: :main, position: 0, hide_header: false)
      sign_in user

      patch toggle_hide_header_shop_admin_cast_page_block_path(block)

      assert_redirected_to shop_admin_cast_page_blocks_path
      assert block.reload.hide_header?
    end
  end
end
