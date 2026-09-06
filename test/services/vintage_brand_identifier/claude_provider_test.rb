require "test_helper"

class VintageBrandIdentifier::ClaudeProviderTest < ActiveSupport::TestCase
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

  SYSTEM_PROMPT = "あなたは古着の鑑定者です。"
  USER_PROMPT = "ニットを判定してください。"
  ANSWER = { brand_candidates: [{ name: "Champion", confidence: "high" }] }.to_json

  test "sends the system prompt, each photo as its own numbered image block, then the question" do
    client = FakeClient.new(text: ANSWER)

    text = provider(client).generate(
      system_prompt: SYSTEM_PROMPT, user_prompt: USER_PROMPT,
      images: [payload("FIRST"), payload("SECOND")]
    )

    assert_equal ANSWER, text
    assert_equal SYSTEM_PROMPT, client.last_params[:system_]
    content = client.last_params[:messages].first[:content]
    images = content.select { |block| block[:type] == "image" }
    assert_equal 2, images.size
    assert_equal "image/png", images.first[:source][:media_type]
    assert_equal "FIRST", Base64.decode64(images.first[:source][:data])
    assert_equal "写真1:", content.first[:text]
    assert_equal USER_PROMPT, content.last[:text]
  end

  test "keeps the token budget above what adaptive thinking needs, at a cost-conscious effort" do
    client = FakeClient.new(text: ANSWER)

    provider(client).generate(system_prompt: SYSTEM_PROMPT, user_prompt: USER_PROMPT, images: [])

    # Opus 5は思考トークンもmax_tokensを食うので、回答が切れない余裕が要る。
    assert_operator client.last_params[:max_tokens], :>=, 8_000
    assert_equal :low, client.last_params[:output_config][:effort]
  end

  test "an answer cut off by the token limit is reported instead of half-parsed" do
    client = FakeClient.new(text: ANSWER[0..10], stop_reason: :max_tokens)

    error = assert_raises(VintageBrandIdentifier::IdentificationError) do
      provider(client).generate(system_prompt: SYSTEM_PROMPT, user_prompt: USER_PROMPT, images: [])
    end

    assert_includes error.message, "長すぎて"
  end

  test "an API failure is turned into a message a visitor can act on" do
    api_error = Anthropic::Errors::APIError.new(url: URI("https://api.anthropic.com"), message: "boom")
    client = FakeClient.new(error: api_error)

    error = assert_raises(VintageBrandIdentifier::IdentificationError) do
      provider(client).generate(system_prompt: SYSTEM_PROMPT, user_prompt: USER_PROMPT, images: [])
    end

    assert_includes error.message, "時間をおいて"
  end

  test "reports itself unconfigured, by name, when no API key is set" do
    unconfigured = VintageBrandIdentifier::ClaudeProvider.new(api_key: nil)

    assert_not unconfigured.configured?
    assert_includes unconfigured.missing_key_message, "ANTHROPIC_API_KEY"
    assert VintageBrandIdentifier::ClaudeProvider.new(api_key: "sk-test").configured?
  end

  private

  def provider(client)
    VintageBrandIdentifier::ClaudeProvider.new(api_key: "sk-test", client: client)
  end

  def payload(bytes)
    { media_type: "image/png", data: bytes }
  end
end
