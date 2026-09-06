require "test_helper"

class VintageBrandIdentifierTest < ActiveSupport::TestCase
  # どのAIに聞くかに関係なく、プロンプトの組み立てと回答の解釈は
  # VintageBrandIdentifier側の仕事。ここではその部分だけを見る。
  class FakeProvider
    attr_reader :system_prompt, :user_prompt, :images

    def initialize(text: nil, error: nil, configured: true)
      @text = text
      @error = error
      @configured = configured
    end

    def configured? = @configured

    def missing_key_message = "AI判定が設定されていません。"

    def generate(system_prompt:, user_prompt:, images:)
      @system_prompt = system_prompt
      @user_prompt = user_prompt
      @images = images
      raise @error if @error

      @text
    end
  end

  RESPONSE = {
    item_type: "スウェット",
    brand_candidates: [
      { name: "Champion(チャンピオン)", confidence: "high", reason: "トリコタグ後期の配色" },
      { name: "不明", confidence: "low", reason: "タグが判読できない場合" }
    ],
    era: "1980年代後半〜1990年代前半",
    era_reason: "トリコタグ後期かつMADE IN USA表記のため",
    origin: "アメリカ製",
    clues: ["袖口がシングルステッチ", "脇にVガゼット"],
    authenticity_notes: ["刺繍タグの糸のほつれ方を確認"],
    next_checks: ["洗濯表示の裏面"],
    market_price: { low: 12_000, high: 25_000, note: "国内のフリマ相場", factors: ["サイズ"] },
    summary: "チャンピオンのリバースウィーブ、80年代後半の個体と見られます。"
  }.to_json

  test "parses the model's JSON answer into a result the view can render" do
    result = identify(FakeProvider.new(text: RESPONSE), notes: "トリコタグ")

    assert_equal "スウェット", result.item_type
    assert_equal "1980年代後半〜1990年代前半", result.era
    assert_equal 2, result.brand_candidates.size
    assert_equal "高い", result.brand_candidates.first.confidence_label
    assert_equal "champion", result.brand_candidates.first.guide_slug
    assert_nil result.brand_candidates.second.guide_slug
    assert_equal "12,000円 〜 25,000円", result.market_price.range_label
    assert_not result.empty?
  end

  test "accepts an answer wrapped in a markdown code fence" do
    result = identify(FakeProvider.new(text: "```json\n#{RESPONSE}\n```"), notes: "トリコタグ")

    assert_equal "スウェット", result.item_type
  end

  test "the prompt carries the same era clues the guide page shows" do
    provider = FakeProvider.new(text: RESPONSE)

    identify(provider, notes: "赤タブ")

    assert_includes provider.user_prompt, "ユニオンチケット"
    assert_includes provider.user_prompt, "Levi's(リーバイス)"
    assert_includes provider.system_prompt, "market_price"
  end

  test "the visitor's condition and size reach the prompt, since the price hangs on them" do
    provider = FakeProvider.new(text: RESPONSE)

    identify(provider, notes: "トリコタグ", condition: "やや傷や汚れあり", size_note: "タグ表記L 肩幅50cm")

    assert_includes provider.user_prompt, "コンディション: やや傷や汚れあり"
    assert_includes provider.user_prompt, "サイズ: タグ表記L 肩幅50cm"
  end

  test "photos reach the provider as bytes with their media type, and are counted in the prompt" do
    provider = FakeProvider.new(text: RESPONSE)
    identification = Vintage::Identification.new(
      notes: "タグ読めず", images: [uploaded_png(bytes: "FIRST"), uploaded_png(bytes: "SECOND")]
    )

    VintageBrandIdentifier.new(identification: identification, provider: provider).call

    assert_equal 2, provider.images.size
    assert_equal "image/png", provider.images.first[:media_type]
    assert_equal "FIRST", provider.images.first[:data]
    assert_includes provider.user_prompt, "写真: 2枚"
  end

  test "an answer that is not JSON is reported as a retryable failure" do
    error = assert_raises(VintageBrandIdentifier::IdentificationError) do
      identify(FakeProvider.new(text: "すみません、判定できませんでした。"), notes: "タグ")
    end

    assert_includes error.message, "もう一度お試しください"
  end

  test "an unconfigured provider says so instead of calling out" do
    error = assert_raises(VintageBrandIdentifier::IdentificationError) do
      identify(FakeProvider.new(configured: false), notes: "タグ")
    end

    assert_includes error.message, "AI判定が設定されていません"
  end

  test "the provider comes from the environment, defaulting to the free-tier one" do
    with_provider_env(nil) do
      assert_equal "gemini", VintageBrandIdentifier.provider_name
      assert_instance_of VintageBrandIdentifier::GeminiProvider, VintageBrandIdentifier.build_provider
    end

    with_provider_env("claude") do
      assert_equal "claude", VintageBrandIdentifier.provider_name
      assert_instance_of VintageBrandIdentifier::ClaudeProvider, VintageBrandIdentifier.build_provider
    end

    # 綴り違いで黙って動かなくなるより、既定に戻したほうが運用しやすい。
    with_provider_env("gemeni") { assert_equal "gemini", VintageBrandIdentifier.provider_name }
  end

  test "the privacy notice names where the photos actually go" do
    with_provider_env(nil) do
      assert_includes VintageBrandIdentifier.privacy_notice, "Google"
      assert_includes VintageBrandIdentifier.privacy_notice, "サービス改善"
    end

    with_provider_env("claude") do
      assert_includes VintageBrandIdentifier.privacy_notice, "Anthropic"
      assert_not_includes VintageBrandIdentifier.privacy_notice, "サービス改善"
    end
  end

  private

  def identify(provider, **attrs)
    VintageBrandIdentifier.new(
      identification: Vintage::Identification.new(**attrs), provider: provider
    ).call
  end

  def with_provider_env(value)
    original = ENV["VINTAGE_AI_PROVIDER"]
    ENV["VINTAGE_AI_PROVIDER"] = value
    yield
  ensure
    ENV["VINTAGE_AI_PROVIDER"] = original
  end

  def uploaded_png(bytes:)
    tempfile = Tempfile.new(["tag", ".png"])
    tempfile.binmode
    tempfile.write(bytes)
    tempfile.rewind
    ActionDispatch::Http::UploadedFile.new(tempfile: tempfile, filename: "tag.png", type: "image/png")
  end
end
