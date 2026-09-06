module Vintage
  # 判定ツールに付随する読み物ページ(年代判定ガイド)。表示内容は
  # Vintage::BrandGuideの定数そのもので、DBには何も持たない。
  class PagesController < BaseController
    def guide
      @common_clues = Vintage::BrandGuide::COMMON_CLUES
      @brands = Vintage::BrandGuide::BRANDS
    end
  end
end
