require "test_helper"
require "ostruct"

class CastTest < ActiveSupport::TestCase
  test "rejects a photo over the 5MB size limit" do
    cast = create_cast
    cast.photos.attach(io: StringIO.new("a" * 6.megabytes), filename: "big.png", content_type: "image/png")

    assert_not cast.valid?
    assert_match(/5MBを超える/, cast.errors[:photos].join)
  end

  test "rejects a non-image content type" do
    cast = create_cast
    cast.photos.attach(io: StringIO.new("not an image"), filename: "evil.exe", content_type: "application/x-msdownload")

    assert_not cast.valid?
    assert_match(/JPEG・PNG・WEBP以外/, cast.errors[:photos].join)
  end

  test "rejects more than 5 attached photos" do
    cast = create_cast
    6.times { |i| cast.photos.attach(**png_upload(filename: "photo#{i}.png")) }

    assert_not cast.valid?
    assert_match(/5枚まで/, cast.errors[:photos].join)
  end

  test "accepts a valid small photo" do
    cast = create_cast
    cast.photos.attach(**png_upload)

    assert cast.valid?
  end

  test "visible_photos excludes photos an admin has hidden" do
    cast = create_cast
    cast.photos.attach(**png_upload(filename: "a.png"))
    cast.photos.attach(**png_upload(filename: "b.png"))
    cast.photos.first.update!(hidden: true)

    assert_equal 1, cast.visible_photos.size
    assert_equal "b.png", cast.visible_photos.first.filename.to_s
  end

  test "photos_removed_by_moderation? is true only once every photo has been hidden" do
    cast = create_cast
    assert_not cast.photos_removed_by_moderation?, "no photos ever uploaded is not the same as removed"

    cast.photos.attach(**png_upload(filename: "a.png"))
    cast.photos.attach(**png_upload(filename: "b.png"))
    assert_not cast.photos_removed_by_moderation?

    cast.photos.first.update!(hidden: true)
    assert_not cast.photos_removed_by_moderation?, "one photo is still visible"

    cast.photos.last.update!(hidden: true)
    assert cast.photos_removed_by_moderation?
  end

  test "validate_new_images rejects a batch that would push the total past 5, without attaching anything" do
    cast = create_cast
    3.times { |i| cast.photos.attach(**png_upload(filename: "existing#{i}.png")) }
    new_files = Array.new(3) { |i| OpenStruct.new(size: 1_000, content_type: "image/png", original_filename: "n#{i}.png") }

    errors = cast.validate_new_images(:photos, new_files)

    assert(errors.any? { |m| m.include?("5枚まで") })
    assert_equal 3, cast.photos.count, "validate_new_images must not attach anything itself"
  end
end
