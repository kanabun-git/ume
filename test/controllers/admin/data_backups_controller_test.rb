require "test_helper"

module Admin
  class DataBackupsControllerTest < ActionDispatch::IntegrationTest
    test "platform admin can download each data category as a tar.gz containing a CSV" do
      shop = create_shop(photos: [png_upload])
      cast = create_cast(shop: shop)
      cast.photos.attach(png_upload)
      diary_entry = create_diary_entry(cast: cast)
      diary_entry.images.attach(png_upload)
      video_block = shop.shop_page_blocks.create!(block_type: :movie, position: 99)
      admin = create_user(role: :platform_admin)
      sign_in admin

      [
        [:admin_data_backups_shops_path, "shops"],
        [:admin_data_backups_casts_path, "casts"],
        [:admin_data_backups_diary_entries_path, "diary_entries"],
        [:admin_data_backups_videos_path, "videos"]
      ].each do |path_helper, label|
        get send(path_helper)

        assert_response :success
        assert_equal "application/gzip", @response.media_type
        assert_match(/#{label}_\d{8}_\d{6}\.tar\.gz/, @response.headers["Content-Disposition"])
        assert @response.body.bytesize.positive?
      end
    end

    test "a shop admin cannot access data backups" do
      shop_admin_user = create_user(role: :shop_admin, shop: create_shop)
      sign_in shop_admin_user

      get admin_data_backups_path

      assert_redirected_to root_path
    end
  end
end
