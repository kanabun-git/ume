require "test_helper"

module Admin
  class ShopPageBlocksControllerTest < ActionDispatch::IntegrationTest
    test "platform admin can view and reorder any shop's page blocks" do
      shop = create_shop
      shop.shop_page_blocks.destroy_all
      admin = create_user(role: :platform_admin)
      first = shop.shop_page_blocks.create!(block_type: :free_text, position: 0)
      second = shop.shop_page_blocks.create!(block_type: :coupon, position: 1)
      sign_in admin

      get admin_shop_shop_page_blocks_path(shop)
      assert_response :success

      patch move_down_admin_shop_shop_page_block_path(shop, first)

      assert_redirected_to admin_shop_shop_page_blocks_path(shop)
      assert_equal 1, first.reload.position
      assert_equal 0, second.reload.position
    end

    test "a shop admin cannot manage another shop's page blocks" do
      shop = create_shop
      other_shop = create_shop
      block = other_shop.shop_page_blocks.first
      shop_admin_user = create_user(role: :shop_admin, shop: shop)
      sign_in shop_admin_user

      get admin_shop_shop_page_blocks_path(other_shop)
      assert_redirected_to root_path

      patch move_down_admin_shop_shop_page_block_path(other_shop, block)
      assert_redirected_to root_path
    end

    test "editing an image_gallery block explains that its photos come from the shop's edit screen" do
      shop = create_shop
      admin = create_user(role: :platform_admin)
      block = shop.shop_page_blocks.find_by!(block_type: :image_gallery)
      sign_in admin

      get edit_admin_shop_shop_page_block_path(shop, block)

      assert_select "a[href=?]", edit_admin_shop_path(shop), text: "店舗情報編集はこちら"
    end
  end
end
