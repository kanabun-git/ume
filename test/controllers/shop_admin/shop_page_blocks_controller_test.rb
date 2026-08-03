require "test_helper"

module ShopAdmin
  class ShopPageBlocksControllerTest < ActionDispatch::IntegrationTest
    test "move_up swaps position with the previous block" do
      shop = create_shop
      shop.shop_page_blocks.destroy_all # clear the blocks auto-seeded on shop creation
      user = create_user(role: :shop_admin, shop: shop)
      first = shop.shop_page_blocks.create!(block_type: :free_text, position: 0)
      second = shop.shop_page_blocks.create!(block_type: :coupon, position: 1)
      sign_in user

      patch move_up_shop_admin_shop_page_block_path(second)

      assert_redirected_to shop_admin_shop_page_blocks_path
      assert_equal 0, second.reload.position
      assert_equal 1, first.reload.position
    end

    # A 3-block list is what actually exercises the ordering: with only 2
    # blocks, "swap with the previous one" and "swap with the first one"
    # give the same result, so a 2-block case alone wouldn't have caught
    # the regression where default_scope's `order(:position)` silently
    # overrode this action's intended `order(position: :desc)`.
    test "move_up on the last of three blocks swaps with its immediate neighbor, not the first block" do
      shop = create_shop
      shop.shop_page_blocks.destroy_all
      user = create_user(role: :shop_admin, shop: shop)
      first = shop.shop_page_blocks.create!(block_type: :free_text, position: 0)
      second = shop.shop_page_blocks.create!(block_type: :coupon, position: 1)
      third = shop.shop_page_blocks.create!(block_type: :price_table, position: 2)
      sign_in user

      patch move_up_shop_admin_shop_page_block_path(third)

      assert_redirected_to shop_admin_shop_page_blocks_path
      assert_equal 0, first.reload.position
      assert_equal 2, second.reload.position
      assert_equal 1, third.reload.position
    end

    test "move_down swaps position with the next block" do
      shop = create_shop
      shop.shop_page_blocks.destroy_all
      user = create_user(role: :shop_admin, shop: shop)
      first = shop.shop_page_blocks.create!(block_type: :free_text, position: 0)
      second = shop.shop_page_blocks.create!(block_type: :coupon, position: 1)
      sign_in user

      patch move_down_shop_admin_shop_page_block_path(first)

      assert_redirected_to shop_admin_shop_page_blocks_path
      assert_equal 1, first.reload.position
      assert_equal 0, second.reload.position
    end

    test "toggle_visibility flips the block's visible flag" do
      shop = create_shop
      shop.shop_page_blocks.destroy_all
      user = create_user(role: :shop_admin, shop: shop)
      block = shop.shop_page_blocks.create!(block_type: :free_text, position: 0, visible: true)
      sign_in user

      patch toggle_visibility_shop_admin_shop_page_block_path(block)

      assert_redirected_to shop_admin_shop_page_blocks_path
      assert_not block.reload.visible?
    end
  end
end
