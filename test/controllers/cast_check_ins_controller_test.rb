require "test_helper"

class CastCheckInsControllerTest < ActionDispatch::IntegrationTest
  test "a signed-in member scanning a cast's QR records a visit with that cast" do
    shop = create_shop
    cast = create_cast(shop: shop, name: "QRキャスト")
    member = create_member
    sign_in member

    get cast_check_in_path(cast.checkin_token)

    assert_response :success
    membership = shop.shop_memberships.find_by(member: member)
    assert membership.present?
    assert_equal 1, membership.visit_count
    visit = membership.shop_visits.first
    assert_equal cast, visit.cast
    assert visit.checked_in_by_qr?
  end

  test "scanning again within 60 minutes does not record a second visit" do
    shop = create_shop
    cast = create_cast(shop: shop)
    member = create_member
    sign_in member

    get cast_check_in_path(cast.checkin_token)
    get cast_check_in_path(cast.checkin_token)

    assert_response :success
    assert_match "記録されませんでした", response.body
    membership = shop.shop_memberships.find_by(member: member)
    assert_equal 1, membership.visit_count
  end

  test "scanning a different cast's QR within 60 minutes still does not record a second visit" do
    shop = create_shop
    cast_a = create_cast(shop: shop)
    cast_b = create_cast(shop: shop)
    member = create_member
    sign_in member

    get cast_check_in_path(cast_a.checkin_token)
    get cast_check_in_path(cast_b.checkin_token)

    membership = shop.shop_memberships.find_by(member: member)
    assert_equal 1, membership.visit_count
  end

  test "scanning again after 60 minutes have passed records a new visit" do
    shop = create_shop
    cast = create_cast(shop: shop)
    member = create_member
    membership = shop.shop_memberships.create!(member: member)
    membership.record_visit!(visited_at: 61.minutes.ago, cast: cast, checked_in_by_qr: true)
    sign_in member

    get cast_check_in_path(cast.checkin_token)

    assert_response :success
    assert_match "来店を記録しました", response.body
    assert_equal 2, membership.reload.visit_count
  end

  test "a signed-out visitor is redirected to sign in and returned to the check-in after logging in" do
    cast = create_cast

    get cast_check_in_path(cast.checkin_token)
    assert_redirected_to new_member_session_path

    member = create_member(password: "password1234")
    post member_session_path, params: { member: { email: member.email, password: "password1234" } }

    assert_redirected_to cast_check_in_path(cast.checkin_token)
  end

  test "an unknown token 404s" do
    get cast_check_in_path("not-a-real-token")

    assert_response :not_found
  end
end
