require "test_helper"

class VintageBrandIdentifierTest < ActiveSupport::TestCase
  # Anthropic::Clientの代わりに渡すテスト用のクライアント。
  # `client.messages.create(...)`だけを受け付け、渡されたパラメータを
  # 記録しつつ、決め打ちの回答テキストを返す。
  class FakeClient
    Block = Struct.new(:type, :text)
    Message = Struct.new(:content, :stop_reason)

    attr_reader :last_params

    def initialize(text: nil, error: nil, stop_reason: :end_turn)
      @text = text
      @error = error
      @stop_reason = stop_reason
    end

    def messages = self

    def create(**params)
      @last_params = params
      raise @error if @error

      Message.new([Block.new(:type, "無視されるブロック"), Block.new(:text, @text)], @stop_reason)
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
    market_price: { low: 12_000, high: 25_000, note: "国内のフリマ相場", factors: ["サイズ", "プリントの状態"] },
    summary: "チャンピオンのリバースウィーブ、80年代後半の個体と見られます。"
  }.to_json

  test "parses the model's JSON answer into a result the view can render" do
    result = VintageBrandIdentifier.new(
      identification: Vintage::Identification.new(notes: "トリコタグ"),
      client: FakeClient.new(text: RESPONSE)
    ).call

    assert_equal "スウェット", result.item_type
    assert_equal "1980年代後半〜1990年代前半", result.era
    assert_equal "アメリカ製", result.origin
    assert_equal 2, result.brand_candidates.size
    assert_equal "高い", result.brand_candidates.first.confidence_label
    assert_equal "champion", result.brand_candidates.first.guide_slug
    assert_nil result.brand_candidates.second.guide_slug
    assert_equal ["袖口がシングルステッチ", "脇にVガゼット"], result.clues
    assert_equal "12,000円 〜 25,000円", result.market_price.range_label
    assert_not result.empty?
  end

  test "accepts an answer wrapped in a markdown code fence" do
    client = FakeClient.new(text: "```json\n#{RESPONSE}\n```")

    result = VintageBrandIdentifier.new(
      identification: Vintage::Identification.new(notes: "トリコタグ"), client: client
    ).call

    assert_equal "スウェット", result.item_type
  end

  test "sends each photo as its own image block, numbered so the answer can cite it" do
    identification = Vintage::Identification.new(
      notes: "タグ読めず", item_type: "ニット", images: [uploaded_png(bytes: "FIRST"), uploaded_png(bytes: "SECOND")]
    )
    client = FakeClient.new(text: RESPONSE)

    VintageBrandIdentifier.new(identification: identification, client: client).call

    content = client.last_params[:messages].first[:content]
    images = content.select { |block| block[:type] == "image" }
    assert_equal 2, images.size
    assert_equal "image/png", images.first[:source][:media_type]
    assert_equal "FIRST", Base64.decode64(images.first[:source][:data])
    assert_equal "写真1:", content.first[:text]
    assert_includes content.last[:text], "ニット"
    assert_includes content.last[:text], "写真: 2枚"
  end

  test "the visitor's condition and size reach the prompt, since the price hangs on them" do
    identification = Vintage::Identification.new(
      notes: "トリコタグ", condition: "やや傷や汚れあり", size_note: "タグ表記L 肩幅50cm"
    )
    client = FakeClient.new(text: RESPONSE)

    VintageBrandIdentifier.new(identification: identification, client: client).call

    prompt = client.last_params[:messages].first[:content].last[:text]
    assert_includes prompt, "コンディション: やや傷や汚れあり"
    assert_includes prompt, "サイズ: タグ表記L 肩幅50cm"
  end

  test "the prompt carries the same era clues the guide page shows" do
    client = FakeClient.new(text: RESPONSE)

    VintageBrandIdentifier.new(
      identification: Vintage::Identification.new(notes: "赤タブ"), client: client
    ).call

    prompt = client.last_params[:messages].first[:content].last[:text]
    assert_includes prompt, "ユニオンチケット"
    assert_includes prompt, "Levi's(リーバイス)"
  end

  test "keeps the token budget above what adaptive thinking needs, at a cost-conscious effort" do
    client = FakeClient.new(text: RESPONSE)

    VintageBrandIdentifier.new(
      identification: Vintage::Identification.new(notes: "タグ"), client: client
    ).call

    # Opus 5は思考トークンもmax_tokensを食うので、回答が切れない余裕が要る。
    assert_operator client.last_params[:max_tokens], :>=, 8_000
    assert_equal :low, client.last_params[:output_config][:effort]
  end

  test "an answer cut off by the token limit is reported instead of half-parsed" do
    # 途中で切れたJSONは Result 側でも解釈に失敗するが、利用者には
    # 「長すぎて受け取れなかった」と伝えたいので stop_reason で先に判定する。
    client = FakeClient.new(text: RESPONSE[0..40], stop_reason: :max_tokens)

    error = assert_raises(VintageBrandIdentifier::IdentificationError) do
      VintageBrandIdentifier.new(
        identification: Vintage::Identification.new(notes: "タグ"), client: client
      ).call
    end

    assert_includes error.message, "長すぎて"
  end

  test "an answer that is not JSON is reported as a retryable failure" do
    client = FakeClient.new(text: "すみません、判定できませんでした。")

    error = assert_raises(VintageBrandIdentifier::IdentificationError) do
      VintageBrandIdentifier.new(
        identification: Vintage::Identification.new(notes: "タグ"), client: client
      ).call
    end

    assert_includes error.message, "もう一度お試しください"
  end

  test "an API failure is turned into a message a visitor can act on" do
    api_error = Anthropic::Errors::APIError.new(url: URI("https://api.anthropic.com"), message: "boom")
    client = FakeClient.new(error: api_error)

    error = assert_raises(VintageBrandIdentifier::IdentificationError) do
      VintageBrandIdentifier.new(
        identification: Vintage::Identification.new(notes: "タグ"), client: client
      ).call
    end

    assert_includes error.message, "時間をおいて"
  end

  test "says so plainly when no API key is configured" do
    original = ENV["ANTHROPIC_API_KEY"]
    ENV["ANTHROPIC_API_KEY"] = nil

    error = assert_raises(VintageBrandIdentifier::IdentificationError) do
      VintageBrandIdentifier.new(identification: Vintage::Identification.new(notes: "タグ")).call
    end

    assert_includes error.message, "AI判定が設定されていません"
  ensure
    ENV["ANTHROPIC_API_KEY"] = original
  end

  private

  def uploaded_png(bytes:)
    tempfile = Tempfile.new(["tag", ".png"])
    tempfile.binmode
    tempfile.write(bytes)
    tempfile.rewind
    ActionDispatch::Http::UploadedFile.new(tempfile: tempfile, filename: "tag.png", type: "image/png")
  end
end
