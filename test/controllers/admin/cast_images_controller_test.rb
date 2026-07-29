require "test_helper"

module Admin
  class CastImagesControllerTest < ActionDispatch::IntegrationTest
    test "platform admin can toggle a cast photo's hidden state" do
      admin = create_user(role: :platform_admin)
      cast = create_cast
      cast.photos.attach(**png_upload)
      photo = cast.photos.first
      sign_in admin

      patch toggle_hidden_admin_cast_image_path(photo)

      assert photo.reload.hidden?
      assert_equal 0, cast.reload.visible_photos.size
    end

    test "a shop admin cannot toggle another shop's cast photo" do
      cast = create_cast
      cast.photos.attach(**png_upload)
      photo = cast.photos.first
      other_shop_admin = create_user(role: :shop_admin, shop: create_shop)
      sign_in other_shop_admin

      patch toggle_hidden_admin_cast_image_path(photo)

      assert_not photo.reload.hidden?
    end

    test "index paginates when there are more casts than fit on one page" do
      admin = create_user(role: :platform_admin)
      25.times { |i| create_cast(name: "ページ確認#{i}").photos.attach(**png_upload) }
      sign_in admin

      get admin_cast_images_path

      assert_response :success
      assert_includes @response.body, "pagination" # Kaminari's default wrapper class
    end
  end
end
