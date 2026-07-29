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

  test "rejects more than 5 attached images" do
    entry = create_diary_entry
    6.times { |i| entry.images.attach(**png_upload(filename: "photo#{i}.png")) }

    assert_not entry.valid?
    assert_match(/5枚まで/, entry.errors[:images].join)
  end
end
