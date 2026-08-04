require "test_helper"

module Admin
  class VideosControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can register a video by URL for any shop" do
      shop = create_shop(name: "動画登録先店舗", area: create_area(region: "関東"))
      admin = create_user(role: :platform_admin)
      sign_in admin

      post admin_videos_path, params: { shop_page_block: { shop_id: shop.id, settings: { video_url: "https://www.youtube.com/embed/dQw4w9WgXcQ" } } }

      assert_redirected_to admin_videos_path
      block = shop.shop_page_blocks.movie.last
      assert_equal "https://www.youtube.com/embed/dQw4w9WgXcQ", block.settings["video_url"]

      get admin_videos_path
      assert_match shop.name, response.body
      assert_match "関東", response.body
    end

    test "a platform admin can upload a video file for a shop" do
      shop = create_shop
      admin = create_user(role: :platform_admin)
      sign_in admin

      file = Rack::Test::UploadedFile.new(StringIO.new("x" * 1024), "video/mp4", original_filename: "sample.mp4")
      post admin_videos_path, params: { shop_page_block: { shop_id: shop.id, video_file: file } }

      assert_redirected_to admin_videos_path
      block = shop.shop_page_blocks.movie.last
      assert block.video_file.attached?
    end

    test "a shop admin cannot access the admin video registration screens" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get admin_videos_path

      assert_redirected_to root_path
    end

    test "a platform admin can edit and delete a registered video" do
      shop = create_shop
      block = shop.shop_page_blocks.create!(block_type: :movie, position: 0, settings: { "video_url" => "https://example.com/a.mp4" })
      admin = create_user(role: :platform_admin)
      sign_in admin

      patch admin_video_path(block), params: { shop_page_block: { shop_id: shop.id, settings: { video_url: "https://example.com/b.mp4" } } }
      assert_equal "https://example.com/b.mp4", block.reload.settings["video_url"]

      delete admin_video_path(block)
      assert_not ShopPageBlock.exists?(block.id)
    end
  end
end
