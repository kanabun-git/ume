require "test_helper"

module ShopAdmin
  class ShopVisitsControllerTest < ActionDispatch::IntegrationTest
    test "a shop admin can record a visit and it awards points" do
      shop = create_shop
      membership = ShopMembership.create!(shop: shop, member: create_member)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_shop_membership_shop_visits_path(membership), params: {
        shop_visit: { visited_on_date: Date.current.to_s, points_earned: 100, memo: "60分コース" }
      }

      assert_redirected_to shop_admin_shop_membership_path(membership)
      assert_equal 1, membership.visit_count
      assert_equal 100, membership.points
    end

    test "a shop admin can record a visit with a cast, designation, and duration" do
      shop = create_shop
      cast = create_cast(shop: shop, name: "テスト嬢")
      membership = ShopMembership.create!(shop: shop, member: create_member)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      post shop_admin_shop_membership_shop_visits_path(membership), params: {
        shop_visit: { visited_on_date: Date.current.to_s, visited_on_time: "19:30", cast_id: cast.id, designation: "main_nomination", duration_minutes: 90 }
      }

      visit = membership.shop_visits.first
      assert_equal cast, visit.cast
      assert visit.main_nomination?
      assert_equal 90, visit.duration_minutes
      assert_equal 19, visit.visited_at.hour
    end

    test "a shop admin cannot record a visit for another shop's membership" do
      other_membership = ShopMembership.create!(shop: create_shop, member: create_member)
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      post shop_admin_shop_membership_shop_visits_path(other_membership), params: { shop_visit: { visited_on_date: Date.current.to_s } }

      assert_response :not_found
    end

    test "a shop admin can edit a visit to fill in the cast/designation/duration later" do
      shop = create_shop
      cast = create_cast(shop: shop, name: "後から指定")
      membership = ShopMembership.create!(shop: shop, member: create_member)
      visit = membership.record_visit!(visited_at: Time.current, checked_in_by_qr: true)
      user = create_user(role: :shop_admin, shop: shop)
      sign_in user

      patch shop_admin_shop_membership_shop_visit_path(membership, visit), params: {
        shop_visit: { visited_on_date: visit.visited_at.to_date.to_s, visited_on_time: "20:00", cast_id: cast.id, designation: "free", duration_minutes: 60, points_earned: 0 }
      }

      assert_redirected_to shop_admin_shop_membership_path(membership)
      visit.reload
      assert_equal cast, visit.cast
      assert visit.free?
      assert_equal 60, visit.duration_minutes
    end

    test "a shop admin cannot edit a visit belonging to another shop's membership" do
      other_membership = ShopMembership.create!(shop: create_shop, member: create_member)
      other_visit = other_membership.record_visit!(visited_at: Time.current)
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get edit_shop_admin_shop_membership_shop_visit_path(other_membership, other_visit)

      assert_response :not_found
    end
  end
end
