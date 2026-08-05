require "test_helper"

module ShopAdmin
  class ShiftsControllerTest < ActionDispatch::IntegrationTest
    test "bulk create registers a shift on every selected weekday within the range" do
      shop = create_shop
      cast = create_cast(shop: shop, name: "ゆい")
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_shifts_path, params: {
        cast_id: cast.id,
        start_date: "2026-08-10", # Monday
        end_date: "2026-08-16", # Sunday
        weekdays: %w[1 3 5],
        start_time: "18:00",
        end_time: "02:00",
        ends_next_day: "1",
        note: "一括登録テスト"
      }

      assert_redirected_to shop_admin_shifts_path
      assert_equal 3, cast.shifts.count
    end

    test "a shop admin cannot bulk-create shifts for another shop's cast" do
      shop = create_shop
      other_cast = create_cast
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_shifts_path, params: {
        cast_id: other_cast.id,
        start_date: "2026-08-10",
        end_date: "2026-08-10",
        weekdays: ["1"],
        start_time: "18:00",
        end_time: "23:00"
      }

      assert_response :not_found
    end

    test "import creates shifts from an uploaded CSV scoped to this shop's casts" do
      shop = create_shop
      create_cast(shop: shop, name: "ゆい")
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      csv = <<~CSV
        キャスト名,勤務日,開始時刻,終了時刻,翌日にまたぐ,メモ
        ゆい,2026-08-10,18:00,23:00,false,
      CSV
      file = Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "shifts.csv")

      post import_shop_admin_shifts_path, params: { file: file }

      assert_redirected_to shop_admin_shifts_path
      assert Shift.exists?(work_date: Date.new(2026, 8, 10))
    end

    test "a shop admin can delete a shift belonging to their own cast" do
      shop = create_shop
      cast = create_cast(shop: shop)
      shift = cast.shifts.create!(work_date: Date.current, start_time: "18:00", end_time: "23:00")
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      delete shop_admin_shift_path(shift)

      assert_redirected_to shop_admin_shifts_path
      assert_not Shift.exists?(shift.id)
    end

    test "a cast cannot access the shop admin bulk shift screens" do
      cast = create_cast
      user = create_user(role: :cast, shop: cast.shop)
      cast.update!(user: user)
      sign_in user

      get shop_admin_shifts_path

      assert_redirected_to root_path
    end
  end
end
