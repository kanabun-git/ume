require "prawn"
require "prawn/measurement_extensions"
require "rqrcode"

# Renders one printable A4 PDF of cast check-in QR business cards -- either
# a single cast's own card (CastPortal::CheckInQrController) or a shop's
# whole roster at once (ShopAdmin/Admin::ShopMembershipsController), for
# handing to customers or leaving on the table.
#
# Layout matches エーワン (A-One) "マルチカード" 91mm×55mm, A4, 10面 stock
# (product codes 51002/51281/51131, among others) -- the most common
# off-the-shelf Japanese business card paper, sold pre-perforated so the
# printed sheet is just torn apart by hand after printing. Its 10-up grid
# (2 columns x 5 rows) has no gap between cards -- the micro-perforation
# itself is the cut line -- so the margins below are derived directly from
# the paper's published card size, not eyeballed:
#   margin_x = (210mm - 91mm*2) / 2 = 14mm
#   margin_y = (297mm - 55mm*5) / 2 = 11mm
# If a different paper is ever needed, add another entry to LAYOUTS and
# pass its key in -- everything else in this class is paper-agnostic.
class CastBusinessCardPdf
  LAYOUTS = {
    a_one_10up: {
      label: "エーワン マルチカード A4 10面 (91×55mm)",
      page_size: "A4",
      columns: 2,
      rows: 5,
      card_width: 91,
      card_height: 55
    }
  }.freeze

  FONT_PATH = Rails.root.join("vendor/fonts/ipa_gothic/ipag.ttf")
  LOGO_PATH = Rails.root.join("app/assets/images/site_logo_square.jpg")

  # The cast's own card (downloaded from her cast portal) shows her name;
  # the shop's bulk roster print does not -- a stack of cards handed out at
  # the shop is meant to be interchangeable, not personally identifying.
  def self.for_cast(cast, base_url:, layout: :a_one_10up)
    new(base_url: base_url, layout: layout, show_name: true).render([cast])
  end

  def self.for_casts(casts, base_url:, layout: :a_one_10up)
    new(base_url: base_url, layout: layout, show_name: false).render(casts)
  end

  def initialize(base_url:, layout:, show_name: true)
    @base_url = base_url
    @layout = LAYOUTS.fetch(layout)
    @show_name = show_name
  end

  # The cast's display name if this instance prints it on the card, nil
  # otherwise -- exposed as its own method (rather than only inline inside
  # draw_card) so the show/hide decision can be asserted directly, without
  # having to parse rendered PDF glyph content (Prawn embeds Japanese text
  # as CID-indexed glyphs, not literal searchable UTF-8 bytes).
  def card_display_name(cast)
    return nil unless @show_name

    cast.alias_name.presence || cast.name
  end

  def render(casts)
    cards_per_page = @layout[:columns] * @layout[:rows]
    margin_x = (page_width_mm - @layout[:card_width] * @layout[:columns]) / 2.0
    margin_y = (page_height_mm - @layout[:card_height] * @layout[:rows]) / 2.0

    document = Prawn::Document.new(page_size: @layout[:page_size], margin: 0)
    # Only one weight is vendored, so map every style to it -- `style:
    # :bold` in draw_card is Prawn's paragraph-level emphasis (fine to
    # render at regular weight), not a claim that a real bold face exists.
    document.font_families.update("IPAGothic" => {
      normal: FONT_PATH.to_s, bold: FONT_PATH.to_s, italic: FONT_PATH.to_s, bold_italic: FONT_PATH.to_s
    })
    document.font "IPAGothic"

    casts.each_slice(cards_per_page).with_index do |page_casts, page_index|
      document.start_new_page if page_index.positive?

      page_casts.each_with_index do |cast, i|
        col = i % @layout[:columns]
        row = i / @layout[:columns]
        x = (margin_x + col * @layout[:card_width]).mm
        y = document.bounds.height - (margin_y + row * @layout[:card_height]).mm

        draw_card(document, cast, x: x, y: y)
      end
    end

    document.render
  end

  private

  def page_width_mm
    @layout[:page_size] == "A4" ? 210 : raise(ArgumentError, "unsupported page size")
  end

  def page_height_mm
    @layout[:page_size] == "A4" ? 297 : raise(ArgumentError, "unsupported page size")
  end

  # Uses `text_box`/`image ... at:` (absolute placement within the card's
  # own bounding box) throughout, never the flowing `text`/`pad` helpers --
  # Prawn's flowing text silently starts a new page when it doesn't fit
  # the remaining space in the current bounds, and on a card this small
  # almost anything overflows, which was scattering one card per page
  # instead of packing 10 onto a sheet.
  def draw_card(document, cast, x:, y:)
    width = @layout[:card_width].mm
    height = @layout[:card_height].mm
    padding = 4

    document.bounding_box([x, y], width: width, height: height) do
      document.stroke_color "CCCCCC"
      document.line_width 0.25
      document.stroke_bounds
      document.fill_color "000000"

      qr_size = height - padding * 2
      qr_png = qr_png_for(cast)
      document.image StringIO.new(qr_png), at: [width - padding - qr_size, height - padding], width: qr_size, height: qr_size

      text_width = width - qr_size - padding * 3
      document.image LOGO_PATH.to_s, at: [padding, height - padding], width: 12

      display_name = card_display_name(cast)

      document.text_box "FuzokuZero", at: [padding, height - padding - 15], width: text_width, height: 8, size: 6, color: "888888", overflow: :shrink_to_fit
      document.text_box "来店ポイントカード", at: [padding, height - padding - 22], width: text_width, height: 8, size: 6, color: "888888", overflow: :shrink_to_fit
      if display_name
        document.text_box cast.shop.name, at: [padding, height - padding - 32], width: text_width, height: 10, size: 7, style: :bold, overflow: :shrink_to_fit
        document.text_box display_name.to_s, at: [padding, height - padding - 42], width: text_width, height: 16, size: 11, style: :bold, overflow: :shrink_to_fit
      else
        document.text_box cast.shop.name, at: [padding, height - padding - 34], width: text_width, height: 24, size: 10, style: :bold, overflow: :shrink_to_fit
      end
      document.text_box "QRを読み込んで\n来店ポイントGET", at: [padding, padding + 14], width: text_width, height: 14, size: 6, color: "555555", overflow: :shrink_to_fit
    end
  end

  def qr_png_for(cast)
    url = Rails.application.routes.url_helpers.cast_check_in_url(cast.checkin_token, host: @base_url)
    qr = RQRCode::QRCode.new(url)
    qr.as_png(size: 400, border_modules: 1).to_s
  end
end
