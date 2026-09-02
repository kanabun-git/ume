require "test_helper"

module CastPortal
  class CheckInQrControllerTest < ActionDispatch::IntegrationTest
    test "a cast can view their own check-in QR code" do
      cast = create_cast
      user = create_user(role: :cast, shop: cast.shop)
      cast.update!(user: user)
      sign_in user

      get cast_check_in_qr_path

      assert_response :success
      assert_match "data:image/png;base64,", response.body
    end

    test "a cast can download their own check-in card as a PDF" do
      cast = create_cast
      user = create_user(role: :cast, shop: cast.shop)
      cast.update!(user: user)
      sign_in user

      get pdf_cast_check_in_qr_path

      assert_response :success
      assert_equal "application/pdf", response.media_type
    end

    test "redirects to the dashboard when the cast has no profile yet" do
      user = create_user(role: :cast, shop: create_shop)
      sign_in user

      get cast_check_in_qr_path

      assert_redirected_to cast_root_path
    end
  end
end
