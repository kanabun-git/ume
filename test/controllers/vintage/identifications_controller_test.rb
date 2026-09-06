require "test_helper"

module Vintage
  class IdentificationsControllerTest < ActionDispatch::IntegrationTest
    # 判定そのものはClaudeへの実リクエストなので、コントローラのテストでは
    # サービスを差し替える。#callだけを持つ最小の代役。
    class FakeIdentifier
      def initialize(result: nil, error: nil)
        @result = result
        @error = error
      end

      def call
        raise @error if @error

        @result
      end
    end

    RESULT_JSON = {
      item_type: "デニムジャケット",
      brand_candidates: [{ name: "Levi's(リーバイス)", confidence: "high", reason: "赤タブがBIG E" }],
      era: "1960年代後半〜1970年代前半",
      era_reason: "BIG Eかつ洗濯表示なし",
      origin: "アメリカ製",
      clues: ["赤タブが大文字のE"],
      authenticity_notes: ["ボタン裏の刻印を確認"],
      next_checks: ["内側の紙パッチ"],
      target_gender: "メンズ",
      target_age: "20代〜40代",
      target_age_reason: "定番のワークウェアで、年齢層を問わず穿かれているため",
      original_price: { low: 12_000, high: 15_000, note: "当時の定価" },
      market_price: {
        low: 60_000, high: 120_000, note: "国内の古着屋での販売価格帯",
        factors: ["サイズ", "リペアの有無"]
      },
      summary: "リーバイスのBIG E期のデニムジャケットと見られます。"
    }.to_json

    EMPTY_RESULT_JSON = {
      brand_candidates: [], next_checks: ["首元のタグを真上から撮影してください"]
    }.to_json

    test "the tool's top page is the judgement form" do
      get vintage_root_path

      assert_response :success
      assert_select "h1", "古着ブランド判定ツール"
      assert_select "form[action=?][enctype=?]", vintage_identifications_path, "multipart/form-data"
      assert_select "input[type=file][multiple]"
    end

    test "a judgement renders the brand candidates, the era and its grounds" do
      post_identification(notes: "赤タブが大文字のE") do
        assert_response :success
      end

      assert_select ".vintage-candidate-name", "Levi's(リーバイス)"
      assert_select ".vintage-confidence", /高い/
      assert_select ".vintage-result-summary", /BIG E期/
      # 結果からガイドの該当ブランドへ飛べること。
      assert_select "a[href=?]", "#{vintage_guide_path}#levis"
    end

    test "the judgement shows the market price range and a way to check real listings" do
      post_identification(notes: "赤タブが大文字のE") do
        assert_response :success
      end

      assert_select ".vintage-price-range", "60,000円 〜 120,000円"
      assert_select ".vintage-price", /国内の古着屋での販売価格帯/
      assert_select ".vintage-price-search a[href*=?]", "mercari"
      # 買取額との取り違えは、相場を出す以上いちばん避けたい誤解。
      assert_select ".vintage-price", /買い取ってもらう金額はこれより低くなります/
    end

    test "the judgement shows the brand's target age range and the original retail price" do
      post_identification(notes: "赤タブが大文字のE") do
        assert_response :success
      end

      assert_select ".vintage-result-label", text: "対象"
      assert_select ".vintage-result-label", text: "想定年齢層"
      assert_select ".vintage-price-secondary .vintage-price-range", "12,000円 〜 15,000円"
      # 想定年齢層が着用者の年齢と取り違えられないよう、画面で断っておく。
      assert_select ".vintage-price-secondary", /この品を着ていた人のことではありません/
    end

    test "underwear is one of the item types the form offers" do
      get vintage_root_path

      assert_select "select#vintage_identification_item_type option", text: "下着・インナー"
    end

    test "no price section when the answer carries no amount" do
      stub_identifier(FakeIdentifier.new(result: result_from(EMPTY_RESULT_JSON))) do
        post vintage_identifications_path, params: { vintage_identification: { notes: "タグ無し" } }
      end

      assert_response :success
      assert_select ".vintage-price", false
    end

    test "the condition and size the visitor picked reach the identifier" do
      identification = nil
      capture = ->(id) { identification = id }
      stub_identifier(FakeIdentifier.new(result: result_from(RESULT_JSON)), capture: capture) do
        post vintage_identifications_path, params: { vintage_identification: {
          notes: "赤タブ", condition: "やや傷や汚れあり", size_note: "W34 L32"
        } }
      end

      assert_response :success
      assert_equal "やや傷や汚れあり", identification.condition
      assert_equal "W34 L32", identification.size_note
    end

    test "a made-up condition is rejected rather than passed through to the AI" do
      called = false
      capture = ->(_id) { called = true }
      stub_identifier(FakeIdentifier.new(result: result_from(RESULT_JSON)), capture: capture) do
        post vintage_identifications_path, params: { vintage_identification: {
          notes: "赤タブ", condition: "新品同様(自由入力)"
        } }
      end

      assert_response :unprocessable_entity
      assert_not called
    end

    test "photos are handed to the identifier" do
      identification = nil
      capture = ->(id) { identification = id }
      stub_identifier(FakeIdentifier.new(result: result_from(RESULT_JSON)), capture: capture) do
        post vintage_identifications_path, params: { vintage_identification: {
          notes: "", item_type: "デニム・パンツ",
          images: [fixture_file_upload_png, fixture_file_upload_png]
        } }
      end

      assert_response :success
      assert_equal 2, identification.images.size
      assert_equal "デニム・パンツ", identification.item_type
    end

    test "a judgement with nothing to go on is rejected before the AI is called" do
      called = false
      capture = ->(_id) { called = true }
      stub_identifier(FakeIdentifier.new(result: result_from(RESULT_JSON)), capture: capture) do
        post vintage_identifications_path, params: { vintage_identification: { notes: "", item_type: "" } }
      end

      assert_response :unprocessable_entity
      assert_not called, "入力が空のときはAIを呼ばずに差し戻す"
      assert_select ".errors", /写真をアップロードするか/
    end

    test "an AI failure comes back on the form instead of a 500" do
      error = ::VintageBrandIdentifier::IdentificationError.new("AIとの通信に失敗しました。")

      stub_identifier(FakeIdentifier.new(error: error)) do
        post vintage_identifications_path, params: { vintage_identification: { notes: "赤タブ" } }
      end

      assert_response :service_unavailable
      assert_select ".errors", /AIとの通信に失敗しました/
      assert_select "form[action=?]", vintage_identifications_path
    end

    test "a judgement the AI could not make explains what to photograph next" do
      stub_identifier(FakeIdentifier.new(result: result_from(EMPTY_RESULT_JSON))) do
        post vintage_identifications_path, params: { vintage_identification: { notes: "タグ無し" } }
      end

      assert_response :success
      assert_select ".vintage-result-empty", /首元のタグを真上から撮影/
    end

    test "a second judgement from the same visitor inside the cooldown is refused" do
      with_real_cache do
        stub_identifier(FakeIdentifier.new(result: result_from(RESULT_JSON))) do
          post vintage_identifications_path, params: { vintage_identification: { notes: "1回目" } }
          assert_response :success

          post vintage_identifications_path, params: { vintage_identification: { notes: "2回目" } }
        end

        assert_response :unprocessable_entity
        assert_select ".errors", /判定の間隔が短すぎます/
      end
    end

    test "a failed judgement does not use up the visitor's cooldown" do
      with_real_cache do
        error = ::VintageBrandIdentifier::IdentificationError.new("AIとの通信に失敗しました。")
        stub_identifier(FakeIdentifier.new(error: error)) do
          post vintage_identifications_path, params: { vintage_identification: { notes: "1回目" } }
          assert_response :service_unavailable
        end

        stub_identifier(FakeIdentifier.new(result: result_from(RESULT_JSON))) do
          post vintage_identifications_path, params: { vintage_identification: { notes: "2回目" } }
        end

        assert_response :success
      end
    end

    private

    def result_from(json)
      Vintage::Result.from_text(json)
    end

    # VintageBrandIdentifier.newを差し替える。capture:を渡すと、
    # コントローラが組み立てたVintage::Identificationを覗ける。
    #
    # Minitest 6でObject#stub(minitest/mock)が本体から外れたので、
    # 特異メソッドの定義と削除で同じことをしている -- .newはClassからの
    # 継承なので、remove_methodすれば元の実装がそのまま戻る。
    def stub_identifier(fake, capture: nil)
      ::VintageBrandIdentifier.define_singleton_method(:new) do |identification:, **|
        capture&.call(identification)
        fake
      end
      yield
    ensure
      ::VintageBrandIdentifier.singleton_class.remove_method(:new)
    end

    def fixture_file_upload_png
      Rack::Test::UploadedFile.new(StringIO.new(png_upload[:io].read), "image/png", original_filename: "tag.png")
    end

    # Corporate::Inquiryのテストと同じ事情(test環境は :null_store)。
    def with_real_cache
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      yield
    ensure
      Rails.cache = original_cache
    end

    def post_identification(notes:)
      stub_identifier(FakeIdentifier.new(result: result_from(RESULT_JSON))) do
        post vintage_identifications_path, params: { vintage_identification: { notes: notes } }
      end
      yield if block_given?
    end
  end
end
