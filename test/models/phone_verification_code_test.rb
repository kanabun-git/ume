require "test_helper"

class PhoneVerificationCodeTest < ActiveSupport::TestCase
  test "issue! creates a 6-digit code that expires in the future" do
    member = create_member

    code = PhoneVerificationCode.issue!(member: member, phone_number: "09012345678")

    assert_match(/\A\d{6}\z/, code.code)
    assert code.expires_at > Time.current
    assert_not code.consumed?
  end

  test "issue! consumes any still-active code for the same member" do
    member = create_member
    first_code = PhoneVerificationCode.issue!(member: member, phone_number: "09012345678")

    PhoneVerificationCode.issue!(member: member, phone_number: "09012345678")

    assert first_code.reload.consumed?
  end
end
