require "test_helper"

module Admin
  class PlansControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can create, update, and delete a plan" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      post admin_plans_path, params: { plan: { name: "テストプラン", monthly_fee: 10000, priority_weight: 1 } }
      assert_redirected_to admin_plans_path
      plan = Plan.find_by(name: "テストプラン")
      assert plan.present?

      patch admin_plan_path(plan), params: { plan: { monthly_fee: 20000 } }
      assert_equal 20000, plan.reload.monthly_fee

      delete admin_plan_path(plan)
      assert_not Plan.exists?(plan.id)
    end

    test "a shop admin cannot access plan management" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get admin_plans_path

      assert_redirected_to root_path
    end

    test "import creates plans from an uploaded CSV" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      csv = <<~CSV
        名前,月額料金,表示優先度,表示順
        インポートプラン,40000,1,1
      CSV
      file = Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "plans.csv")

      post import_admin_plans_path, params: { file: file }

      assert_redirected_to admin_plans_path
      assert Plan.exists?(name: "インポートプラン")
    end

    test "template downloads a CSV with the expected headers" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      get template_admin_plans_path

      assert_response :success
      assert_match "月額料金", response.body
    end

    test "export downloads a CSV of the current plans" do
      admin = create_user(role: :platform_admin)
      sign_in admin
      Plan.create!(name: "エクスポート対象プラン", monthly_fee: 1000, priority_weight: 1)

      get export_admin_plans_path

      assert_response :success
      assert_match "エクスポート対象プラン", response.body
    end
  end
end
