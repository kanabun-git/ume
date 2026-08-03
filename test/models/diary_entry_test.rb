require "test_helper"

class DiaryEntryTest < ActiveSupport::TestCase
  test "visible_images excludes images an admin has hidden" do
    entry = create_diary_entry
    entry.images.attach(**png_upload(filename: "a.png"))
    entry.images.attach(**png_upload(filename: "b.png"))
    entry.images.first.update!(hidden: true)

    assert_equal 1, entry.visible_images.size
    assert_equal "b.png", entry.visible_images.first.filename.to_s
  end

  test "content_removed_by_moderation? is true only once every image and the video have been hidden" do
    entry = create_diary_entry
    assert_not entry.content_removed_by_moderation?, "nothing ever uploaded is not the same as removed"

    entry.images.attach(**png_upload(filename: "a.png"))
    assert_not entry.content_removed_by_moderation?

    entry.images.first.update!(hidden: true)
    assert entry.content_removed_by_moderation?

    entry.video.attach(io: StringIO.new("fake video"), filename: "v.mp4", content_type: "video/mp4")
    assert_not entry.content_removed_by_moderation?, "the video is still visible"

    entry.video.attachment.update!(hidden: true)
    assert entry.content_removed_by_moderation?
    assert entry.video_hidden?
  end

  test "rejects more than 5 attached images" do
    entry = create_diary_entry
    6.times { |i| entry.images.attach(**png_upload(filename: "photo#{i}.png")) }

    assert_not entry.valid?
    assert_match(/5枚まで/, entry.errors[:images].join)
  end
end
