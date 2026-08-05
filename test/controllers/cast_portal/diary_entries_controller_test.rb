require "test_helper"

module CastPortal
  class DiaryEntriesControllerTest < ActionDispatch::IntegrationTest
    test "a cast can schedule a diary entry to publish in the future" do
      cast = create_cast
      user = create_user(role: :cast, shop: cast.shop)
      cast.update!(user: user)
      sign_in user

      future_time = 1.day.from_now.change(sec: 0)

      post cast_diary_entries_path, params: {
        diary_entry: { title: "予約日記", body: "本文", status: :published, published_at: future_time }
      }

      entry = DiaryEntry.find_by(title: "予約日記")
      assert entry.scheduled?
      assert_not DiaryEntry.visible.include?(entry)
    end

    test "leaving published_at blank on a published entry publishes it immediately" do
      cast = create_cast
      user = create_user(role: :cast, shop: cast.shop)
      cast.update!(user: user)
      sign_in user

      post cast_diary_entries_path, params: {
        diary_entry: { title: "即時日記", body: "本文", status: :published, published_at: "" }
      }

      entry = DiaryEntry.find_by(title: "即時日記")
      assert_not entry.scheduled?
      assert DiaryEntry.visible.include?(entry)
    end
  end
end
