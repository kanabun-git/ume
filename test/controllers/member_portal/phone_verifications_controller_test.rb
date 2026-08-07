require "test_helper"

module MemberPortal
  class PhoneVerificationsControllerTest < ActionDispatch::IntegrationTest
    test "a member can request a code and verify it to complete phone verification" do
      member = create_member
      sign_in member

      post member_phone_verification_path, params: { phone_number: "09012345678" }
      assert_redirected_to edit_member_phone_verification_path

      code = member.phone_verification_codes.active.order(created_at: :desc).first

      patch member_phone_verification_path, params: { code: code.code }

      assert_redirected_to member_root_path
      assert member.reload.phone_verified?
      assert_equal "09012345678", member.phone_number
    end

    test "an incorrect code does not verify the member" do
      member = create_member
      sign_in member
      PhoneVerificationCode.issue!(member: member, phone_number: "09012345678")

      patch member_phone_verification_path, params: { code: "000000" }

      assert_redirected_to edit_member_phone_verification_path
      assert_not member.reload.phone_verified?
    end

    test "return_to is honored after successful verification" do
      shop = create_shop
      member = create_member
      sign_in member

      get new_member_phone_verification_path(return_to: shop_path(shop))
      post member_phone_verification_path, params: { phone_number: "09012345678" }
      code = member.phone_verification_codes.active.order(created_at: :desc).first

      patch member_phone_verification_path, params: { code: code.code }

      assert_redirected_to shop_path(shop)
    end
  end
end
