require "test_helper"

class CastsControllerTest < ActionDispatch::IntegrationTest
  test "lists active casts from approved shops" do
    active_cast = create_cast(name: "在籍キャスト")
    inactive_cast = create_cast(name: "退店キャスト", status: :inactive)
    suspended_cast = create_cast(shop: create_shop(status: :suspended), name: "停止店キャスト")

    get casts_path

    assert_response :success
    assert_match active_cast.name, response.body
    assert_no_match inactive_cast.name, response.body
    assert_no_match suspended_cast.name, response.body
  end

  test "show 404s for a cast whose shop is suspended" do
    suspended_cast = create_cast(shop: create_shop(status: :suspended))

    get cast_path(suspended_cast)

    assert_response :not_found
  end

  test "show 404s for a cast whose shop is unpublished (draft)" do
    cast = create_cast(shop: create_shop(published: false))

    get cast_path(cast)

    assert_response :not_found
  end

  test "the shop's own admin can preview a cast whose shop is unpublished" do
    shop = create_shop(published: false)
    cast = create_cast(shop: shop, name: "下書き中のキャスト")
    user = create_user(role: :shop_admin, shop: shop)
    sign_in user

    get cast_path(cast)

    assert_response :success
    assert_includes response.body, cast.name
  end

  test "previewing a cast on an unpublished shop does not record a view" do
    shop = create_shop(published: false)
    cast = create_cast(shop: shop)
    user = create_user(role: :shop_admin, shop: shop)
    sign_in user

    get cast_path(cast)

    assert_equal 0, cast.reload.view_count
    assert_nil CastDailyView.find_by(cast: cast, view_date: Date.current)
  end

  test "viewing a cast records a daily view and increments its view count" do
    cast = create_cast

    get cast_path(cast)
    get cast_path(cast)

    assert_equal 2, cast.reload.view_count
    daily_view = CastDailyView.find_by(cast: cast, view_date: Date.current)
    assert_equal 2, daily_view.views_count
  end

  test "filters by area_id" do
    matching_area = create_area
    other_area = create_area
    matching_cast = create_cast(shop: create_shop(area: matching_area), name: "対象エリアキャスト")
    other_cast = create_cast(shop: create_shop(area: other_area), name: "対象外エリアキャスト")

    get casts_path, params: { area_id: matching_area.id }

    assert_response :success
    assert_match matching_cast.name, response.body
    assert_no_match other_cast.name, response.body
  end

  test "filters by cup size" do
    d_cup_cast = create_cast(name: "Dカップキャスト", cup: "D")
    c_cup_cast = create_cast(name: "Cカップキャスト", cup: "C")

    get casts_path, params: { cup: "D" }

    assert_response :success
    assert_match d_cup_cast.name, response.body
    assert_no_match c_cup_cast.name, response.body
  end

  test "filters by age range" do
    younger = create_cast(name: "20歳キャスト", age: 20)
    older = create_cast(name: "35歳キャスト", age: 35)

    get casts_path, params: { min_age: 25, max_age: 40 }

    assert_response :success
    assert_match older.name, response.body
    assert_no_match younger.name, response.body
  end

  test "filters by height range" do
    shorter = create_cast(name: "低身長キャスト", height: 150)
    taller = create_cast(name: "高身長キャスト", height: 170)

    get casts_path, params: { min_height: 160, max_height: 180 }

    assert_response :success
    assert_match taller.name, response.body
    assert_no_match shorter.name, response.body
  end

  test "filters to trial casts only" do
    trial_cast = create_cast(name: "体験入店キャスト", is_trial: true)
    regular_cast = create_cast(name: "通常キャスト", is_trial: false)

    get casts_path, params: { trial: "1" }

    assert_response :success
    assert_match trial_cast.name, response.body
    assert_no_match regular_cast.name, response.body
  end

  test "filters by keyword matching name or catch_copy" do
    matching_cast = create_cast(name: "未経験キャスト", catch_copy: "未経験の新人です")
    other_cast = create_cast(name: "ベテランキャスト", catch_copy: "経験豊富です")

    get casts_path, params: { keyword: "未経験" }

    assert_response :success
    assert_match matching_cast.name, response.body
    assert_no_match other_cast.name, response.body
  end

  test "a cast page block shows its title band and frame by default, in both columns" do
    cast = create_cast
    cast.shop.cast_page_blocks.destroy_all
    main_block = cast.shop.cast_page_blocks.create!(block_type: :free_text, layout_column: :main, position: 0, settings: { "body" => "メイン本文" })
    side_block = cast.shop.cast_page_blocks.create!(block_type: :free_text, layout_column: :side, position: 0, settings: { "body" => "サイド本文" })

    get cast_path(cast)

    assert_select "div.obi-header", text: main_block.label
    assert_select "div.obi-body", text: /メイン本文/
    assert_select "div.obi-body", text: /サイド本文/
    assert_no_match "no-header", response.body
  end

  test "hide_header removes the title band and frame but keeps content, in both columns" do
    cast = create_cast
    cast.shop.cast_page_blocks.destroy_all
    cast.shop.cast_page_blocks.create!(block_type: :free_text, layout_column: :main, position: 0, hide_header: true, settings: { "body" => "メイン本文" })
    cast.shop.cast_page_blocks.create!(block_type: :free_text, layout_column: :side, position: 0, hide_header: true, settings: { "body" => "サイド本文" })

    get cast_path(cast)

    assert_select "div.obi-header", count: 0
    assert_select "div.obi-block.no-header" do
      assert_select "div.obi-body.no-header"
    end
    assert_match "メイン本文", response.body
    assert_match "サイド本文", response.body
  end

  test "a cast page block with visible off does not render at all, content included" do
    cast = create_cast
    cast.shop.cast_page_blocks.destroy_all
    cast.shop.cast_page_blocks.create!(block_type: :free_text, layout_column: :main, position: 0, visible: false, settings: { "body" => "見えないはずの本文" })

    get cast_path(cast)

    assert_no_match "見えないはずの本文", response.body
  end
end
