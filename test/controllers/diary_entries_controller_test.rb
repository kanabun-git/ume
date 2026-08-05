require "test_helper"

class DiaryEntriesControllerTest < ActionDispatch::IntegrationTest
  test "lists published diary entries" do
    entry = create_diary_entry(title: "公開日記")

    get diary_entries_path

    assert_response :success
    assert_match entry.title, response.body
  end

  test "excludes a diary entry whose shop is suspended" do
    suspended_cast = create_cast(shop: create_shop(status: :suspended))
    hidden_entry = create_diary_entry(cast: suspended_cast, title: "停止店の日記")

    get diary_entries_path

    assert_response :success
    assert_no_match hidden_entry.title, response.body
  end

  test "filters by area_id" do
    matching_area = create_area
    other_area = create_area
    matching_entry = create_diary_entry(cast: create_cast(shop: create_shop(area: matching_area)), title: "対象エリア日記")
    other_entry = create_diary_entry(cast: create_cast(shop: create_shop(area: other_area)), title: "対象外エリア日記")

    get diary_entries_path, params: { area_id: matching_area.id }

    assert_response :success
    assert_match matching_entry.title, response.body
    assert_no_match other_entry.title, response.body
  end

  test "filters by genre_id" do
    matching_genre = create_genre
    other_genre = create_genre
    matching_entry = create_diary_entry(cast: create_cast(shop: create_shop(genre: matching_genre)), title: "対象ジャンル日記")
    other_entry = create_diary_entry(cast: create_cast(shop: create_shop(genre: other_genre)), title: "対象外ジャンル日記")

    get diary_entries_path, params: { genre_id: matching_genre.id }

    assert_response :success
    assert_match matching_entry.title, response.body
    assert_no_match other_entry.title, response.body
  end
end
