require "test_helper"

class Corporate::PagesControllerTest < ActionDispatch::IntegrationTest
  test "top page shows the company name and links to the other corporate pages" do
    get corporate_root_path

    assert_response :success
    assert_match Corporate::Company::NAME, response.body
    assert_select "a[href=?]", corporate_company_path
    assert_select "a[href=?]", corporate_business_path
    assert_select "a[href=?]", new_corporate_inquiry_path
  end

  test "company page shows the 会社概要 table" do
    get corporate_company_path

    assert_response :success
    assert_match Corporate::Company::NAME, response.body
    assert_match Corporate::Company::REPRESENTATIVE, response.body
  end

  test "business page lists each business line" do
    get corporate_business_path

    assert_response :success
    Corporate::Company::BUSINESS_LINES.each do |line|
      assert_match line[:title], response.body
    end
  end

  test "the やどかりペンションHP business line links to the inquiry form with its subject preselected" do
    get corporate_business_path

    assert_response :success
    assert_select "a[href=?]", new_corporate_inquiry_path(subject: "やどかりペンションお問い合わせ")
  end

  test "access page shows the address" do
    get corporate_access_path

    assert_response :success
    assert_match Corporate::Company::ADDRESS, response.body
  end
end
