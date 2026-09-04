require "test_helper"

class Corporate::InquiriesControllerTest < ActionDispatch::IntegrationTest
  test "a normal inquiry submission notifies the admin by email and shows a confirmation" do
    assert_emails 1 do
      post corporate_inquiries_path, params: { corporate_inquiry: {
        subject: "その他", name: "問合太郎", company_name: "テスト株式会社", email: "taro@example.com",
        phone: "03-1111-2222", message: "取引についてご相談があります"
      } }
    end

    assert_response :success
    assert_match "お問い合わせを受け付けました", response.body
  end

  test "filling the honeypot field shows the same confirmation without emailing" do
    assert_no_emails do
      post corporate_inquiries_path, params: { corporate_inquiry: {
        subject: "その他", name: "bot", email: "bot@example.com", message: "spam", website: "http://spam.example"
      } }
    end

    assert_response :success
    assert_match "お問い合わせを受け付けました", response.body
  end

  test "a missing required field re-renders the form with an error" do
    post corporate_inquiries_path, params: { corporate_inquiry: { subject: "その他", name: "問合太郎" } }

    assert_response :unprocessable_entity
  end

  test "a subject outside the allowed pulldown values re-renders the form with an error" do
    post corporate_inquiries_path, params: { corporate_inquiry: {
      subject: "でたらめな件名", name: "問合太郎", email: "taro@example.com", message: "本文"
    } }

    assert_response :unprocessable_entity
  end

  test "the new form preselects the subject pulldown from the subject query param" do
    get new_corporate_inquiry_path(subject: "やどかりペンションお問い合わせ")

    assert_response :success
    assert_select "option[selected][value=?]", "やどかりペンションお問い合わせ"
  end

  test "an unrecognized subject query param is ignored, leaving the pulldown unselected" do
    get new_corporate_inquiry_path(subject: "でたらめな件名")

    assert_response :success
    assert_select "option[selected]", false
  end

  # The test environment runs with `config.cache_store = :null_store` (see
  # config/environments/test.rb), which makes every Rails.cache call a
  # no-op -- exactly what the rate limit relies on to work at all. Swap in
  # a real in-memory store just for these two tests so the cooldown is
  # actually exercised, restoring :null_store afterward.
  def with_real_cache
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original_cache
  end

  test "a second submission from the same IP within the cooldown is rejected without emailing" do
    with_real_cache do
      post corporate_inquiries_path, params: { corporate_inquiry: {
        subject: "その他", name: "問合太郎", email: "taro@example.com", message: "1件目"
      } }

      assert_no_emails do
        post corporate_inquiries_path, params: { corporate_inquiry: {
          subject: "その他", name: "問合次郎", email: "jiro@example.com", message: "2件目"
        } }
      end

      assert_response :unprocessable_entity
    end
  end

  test "a submission after the cooldown has passed succeeds" do
    with_real_cache do
      post corporate_inquiries_path, params: { corporate_inquiry: {
        subject: "その他", name: "問合太郎", email: "taro@example.com", message: "1件目"
      } }

      travel Corporate::Inquiry::GLOBAL_COOLDOWN + 1.second
      assert_emails 1 do
        post corporate_inquiries_path, params: { corporate_inquiry: {
          subject: "その他", name: "問合次郎", email: "jiro@example.com", message: "2件目"
        } }
      end

      assert_response :success
    end
  end
end
