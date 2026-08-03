require "test_helper"

module Admin
  class DiaryImagesControllerTest < ActionDispatch::IntegrationTest
    test "index lists diary entries that have only a video, with no images" do
      admin = create_user(role: :platform_admin)
      entry = create_diary_entry
      entry.video.attach(io: StringIO.new("fake video"), filename: "v.mp4", content_type: "video/mp4")
      sign_in admin

      get admin_diary_images_path

      assert_response :success
      assert_includes @response.body, entry.title
    end

    test "platform admin can toggle a diary entry's video hidden state" do
      admin = create_user(role: :platform_admin)
      entry = create_diary_entry
      entry.video.attach(io: StringIO.new("fake video"), filename: "v.mp4", content_type: "video/mp4")
      sign_in admin

      patch admin_toggle_video_hidden_diary_entry_path(entry)

      assert_redirected_to admin_diary_images_path
      assert entry.reload.video_hidden?
    end

    test "a shop admin cannot access diary video moderation at all" do
      entry = create_diary_entry
      entry.video.attach(io: StringIO.new("fake video"), filename: "v.mp4", content_type: "video/mp4")
      shop_admin_user = create_user(role: :shop_admin, shop: create_shop)
      sign_in shop_admin_user

      patch admin_toggle_video_hidden_diary_entry_path(entry)

      assert_redirected_to root_path
      assert_not entry.reload.video_hidden?
    end
  end
end
