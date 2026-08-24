require "test_helper"

# Guards against the layout partial silently disappearing again -- see
# app/views/layouts/_turbo_confirm_shim.html.erb for why every layout needs
# this (Turbo Drive's own confirm-dialog JS is never loaded in this app).
class TurboConfirmShimTest < ActionDispatch::IntegrationTest
  test "the public application layout includes the confirm shim" do
    get root_path

    assert_select "script", text: /data-turbo-confirm/
  end

  test "the admin layout includes the confirm shim" do
    admin = create_user(role: :platform_admin)
    sign_in admin

    get admin_root_path

    assert_select "script", text: /data-turbo-confirm/
  end

  test "the shop_admin layout includes the confirm shim" do
    shop = create_shop
    user = create_user(role: :shop_admin, shop: shop)
    sign_in user

    get shop_admin_root_path

    assert_select "script", text: /data-turbo-confirm/
  end

  test "the cast layout includes the confirm shim" do
    shop = create_shop
    cast = create_cast(shop: shop)
    user = create_user(role: :cast, shop: shop)
    cast.update!(user: user)

    sign_in user

    get cast_root_path

    assert_select "script", text: /data-turbo-confirm/
  end
end
