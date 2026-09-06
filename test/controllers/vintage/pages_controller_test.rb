require "test_helper"

module Vintage
  class PagesControllerTest < ActionDispatch::IntegrationTest
    test "the era guide lists the common clues and every brand's tag history" do
      get vintage_guide_path

      assert_response :success
      assert_select "h1", "年代判定ガイド"
      assert_select ".vintage-card", Vintage::BrandGuide::COMMON_CLUES.size
      assert_select ".vintage-brand", Vintage::BrandGuide::BRANDS.size
    end

    test "each brand has an anchor the judgement result can link to" do
      get vintage_guide_path

      Vintage::BrandGuide::BRANDS.each do |brand|
        assert_select "##{brand[:slug]}"
      end
    end
  end
end
