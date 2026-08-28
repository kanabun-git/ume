require "test_helper"

class MaintenanceModeTest < ActionDispatch::IntegrationTest
  test "public pages show the default message when maintenance mode is on with no customization" do
    with_maintenance_mode_on do
      get root_path

      assert_response :service_unavailable
      assert_select "h1", "ただいまメンテナンス中です"
      assert_select "p", text: /ただいまサイトのメンテナンスを行っております/
    end
  end

  test "a custom message replaces the default text" do
    SiteSetting.instance.update!(maintenance_message: "臨時メンテナンス中です")

    with_maintenance_mode_on do
      get root_path

      assert_select "p", text: /臨時メンテナンス中です/
    end
  end

  test "a maintenance image drops the heading, message, and card -- only the image and banner remain" do
    setting = SiteSetting.instance
    setting.update!(maintenance_message: "このメッセージは表示されないはず")
    setting.maintenance_image.attach(png_upload(filename: "maintenance.png"))

    with_maintenance_mode_on do
      get root_path

      assert_select ".maintenance-image img"
      assert_select "p", text: /このメッセージは表示されないはず/, count: 0
      assert_select "h1", count: 0
      assert_select ".card", count: 0
      assert_select "a.maintenance-banner-link[href=?]", new_shop_inquiry_path
    end
  end

  test "with no banner image, a text link to the shop inquiry page is shown" do
    with_maintenance_mode_on do
      get root_path

      assert_select "a.maintenance-banner-link[href=?]", new_shop_inquiry_path
    end
  end

  test "with a banner image, it links to the shop inquiry page instead of the text link" do
    SiteSetting.instance.maintenance_banner_image.attach(png_upload(filename: "banner.png"))

    with_maintenance_mode_on do
      get root_path

      assert_select ".maintenance-banner a[href=?] img", new_shop_inquiry_path
      assert_select "a.maintenance-banner-link", count: 0
    end
  end

  test "the shop inquiry pages stay reachable during maintenance" do
    with_maintenance_mode_on do
      get new_shop_inquiry_path
      assert_response :success
    end
  end

  test "the admin, shop_admin, and cast portal areas stay reachable during maintenance" do
    with_maintenance_mode_on do
      get new_user_session_path
      assert_response :success
    end
  end

  test "an anonymous visitor cannot preview a shop or cast page during maintenance" do
    shop = create_shop
    cast = create_cast(shop: shop)

    with_maintenance_mode_on do
      get shop_path(shop)
      assert_response :service_unavailable

      get cast_path(cast)
      assert_response :service_unavailable
    end
  end

  test "a platform admin can preview any shop or cast page during maintenance" do
    shop = create_shop
    cast = create_cast(shop: shop)
    admin = create_user(role: :platform_admin)
    sign_in admin

    with_maintenance_mode_on do
      get shop_path(shop)
      assert_response :success

      get cast_path(cast)
      assert_response :success
    end
  end

  test "a shop admin can preview their own shop and cast pages during maintenance" do
    shop = create_shop
    cast = create_cast(shop: shop)
    shop_admin = create_user(role: :shop_admin, shop: shop)
    sign_in shop_admin

    with_maintenance_mode_on do
      get shop_path(shop)
      assert_response :success

      get cast_path(cast)
      assert_response :success
    end
  end

  test "a shop admin cannot preview another shop's page during maintenance" do
    shop = create_shop
    other_shop = create_shop
    shop_admin = create_user(role: :shop_admin, shop: shop)
    sign_in shop_admin

    with_maintenance_mode_on do
      get shop_path(other_shop)
      assert_response :service_unavailable
    end
  end

  private

  def with_maintenance_mode_on
    SiteSetting.instance.update!(maintenance_mode: true)
    yield
  ensure
    SiteSetting.instance.update!(maintenance_mode: false)
  end
end
