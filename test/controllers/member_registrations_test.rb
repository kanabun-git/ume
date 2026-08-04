require "test_helper"

class MemberRegistrationsTest < ActionDispatch::IntegrationTest
  test "a visitor can sign up as a member and lands on their mypage" do
    post member_registration_path, params: {
      member: {
        name: "新規会員",
        email: "new-member-#{SecureRandom.hex(4)}@example.com",
        password: "password1234",
        password_confirmation: "password1234"
      }
    }

    assert_redirected_to member_root_path
    assert Member.exists?(name: "新規会員")
  end
end
