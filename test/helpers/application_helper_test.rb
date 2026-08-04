require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "video_thumbnail_tag renders the real YouTube thumbnail image for a YouTube URL" do
    block = create_shop.shop_page_blocks.create!(
      block_type: :movie, position: 0,
      settings: { "video_url" => "https://www.youtube.com/embed/dQw4w9WgXcQ" }
    )

    html = video_thumbnail_tag(block)

    assert_match "https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg", html
    assert_match "<img", html
  end

  test "video_thumbnail_tag renders a muted video tag for a non-YouTube URL" do
    block = create_shop.shop_page_blocks.create!(
      block_type: :movie, position: 0,
      settings: { "video_url" => "https://example.com/sample.mp4" }
    )

    html = video_thumbnail_tag(block)

    assert_match "<video", html
    assert_match "muted", html
    assert_match "https://example.com/sample.mp4", html
  end

  test "video_thumbnail_tag renders nothing when there is no video" do
    block = create_shop.shop_page_blocks.create!(block_type: :movie, position: 0)

    assert_nil video_thumbnail_tag(block)
  end
end
