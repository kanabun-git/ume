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

  test "scheduled? is true for a published entry whose published_at is still in the future" do
    entry = create_diary_entry(status: :published, published_at: 1.day.from_now)

    assert entry.scheduled?
    assert_not DiaryEntry.visible.include?(entry)
  end

  test "scheduled? is false once published_at has passed" do
    entry = create_diary_entry(status: :published, published_at: 1.day.ago)

    assert_not entry.scheduled?
    assert DiaryEntry.visible.include?(entry)
  end

  test "scheduled? is false for a draft even with a future published_at" do
    entry = create_diary_entry(status: :draft, published_at: 1.day.from_now)

    assert_not entry.scheduled?
  end

  test "rejects more than 5 attached images" do
    entry = create_diary_entry
    6.times { |i| entry.images.attach(**png_upload(filename: "photo#{i}.png")) }

    assert_not entry.valid?
    assert_match(/5枚まで/, entry.errors[:images].join)
  end
end
