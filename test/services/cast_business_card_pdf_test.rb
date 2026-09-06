require "test_helper"

class CastBusinessCardPdfTest < ActiveSupport::TestCase
  test "for_cast renders a non-empty PDF" do
    cast = create_cast

    pdf = CastBusinessCardPdf.for_cast(cast, base_url: "https://fuzoku-zero.com")

    assert pdf.start_with?("%PDF")
  end

  test "for_casts packs up to 10 cards per page" do
    shop = create_shop
    casts = 12.times.map { |i| create_cast(shop: shop, name: "テスト#{i}") }

    pdf = CastBusinessCardPdf.for_casts(casts, base_url: "https://fuzoku-zero.com")

    # A 2-page PDF (10 on page 1, 2 on page 2) has two "/Type /Page" page
    # objects, distinguishing it from Prawn dumping one page per card.
    assert_equal 2, pdf.scan(%r{/Type\s*/Page[^s]}).size
  end

  test "for_casts with an empty list still renders a valid (blank) PDF" do
    pdf = CastBusinessCardPdf.for_casts([], base_url: "https://fuzoku-zero.com")

    assert pdf.start_with?("%PDF")
  end

  test "individual cast cards print the cast's name" do
    cast = create_cast(name: "個別カード確認")

    renderer = CastBusinessCardPdf.new(base_url: "https://fuzoku-zero.com", layout: :a_one_10up, show_name: true)

    assert_equal "個別カード確認", renderer.card_display_name(cast)
  end

  test "the bulk shop roster print omits each cast's name" do
    cast = create_cast(name: "一括カード確認")

    renderer = CastBusinessCardPdf.new(base_url: "https://fuzoku-zero.com", layout: :a_one_10up, show_name: false)

    assert_nil renderer.card_display_name(cast)
  end
end
