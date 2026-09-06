require "test_helper"

class VintageBrandIdentifier::GeminiProviderTest < ActiveSupport::TestCase
  # 実際のHTTPの代わりに、送られたペイロードを記録して決め打ちの
  # レスポンスを返すだけの差し替え口。
  class FakeTransport
    attr_reader :last_payload

    def initialize(status: 200, body: nil, error: nil)
      @status = status
      @body = body
      @error = error
    end

    def call(payload)
      @last_payload = payload
      raise @error if @error

      [@status, @body]
    end
  end

  SYSTEM_PROMPT = "あなたは古着の鑑定者です。"
  USER_PROMPT = "スウェットを判定してください。"
  ANSWER = { brand_candidates: [{ name: "Champion", confidence: "high" }] }.to_json

  test "sends the system instruction, numbered inline images and the question, and asks for JSON back" do
    transport = FakeTransport.new(body: { output_text: ANSWER }.to_json)

    text = provider(transport).generate(
      system_prompt: SYSTEM_PROMPT, user_prompt: USER_PROMPT,
      images: [payload("FIRST"), payload("SECOND")]
    )

    assert_equal ANSWER, text
    assert_equal "key-test", transport.last_payload[:api_key]

    body = JSON.parse(transport.last_payload[:body])
    assert_equal SYSTEM_PROMPT, body["system_instruction"]
    assert_equal "application/json", body.dig("response_format", "mime_type")

    images = body["input"].select { |part| part["type"] == "image" }
    assert_equal 2, images.size
    assert_equal "image/png", images.first["mime_type"]
    assert_equal "FIRST", Base64.decode64(images.first["data"])
    assert_equal "写真1:", body["input"].first["text"]
    assert_equal USER_PROMPT, body["input"].last["text"]
  end

  test "uses a free-tier model by default and lets the environment name another one" do
    transport = FakeTransport.new(body: { output_text: ANSWER }.to_json)

    provider(transport).generate(system_prompt: SYSTEM_PROMPT, user_prompt: USER_PROMPT, images: [])
    assert_equal VintageBrandIdentifier::GeminiProvider::DEFAULT_MODEL,
                 JSON.parse(transport.last_payload[:body])["model"]

    named = VintageBrandIdentifier::GeminiProvider.new(
      api_key: "key-test", model: "gemini-3.5-flash-lite", transport: transport
    )
    named.generate(system_prompt: SYSTEM_PROMPT, user_prompt: USER_PROMPT, images: [])
    assert_equal "gemini-3.5-flash-lite", JSON.parse(transport.last_payload[:body])["model"]
  end

  test "falls back to reading the answer out of the response steps" do
    body = { steps: [{ type: "model_response", content: [{ type: "text", text: ANSWER }] }] }.to_json

    text = provider(FakeTransport.new(body: body)).generate(
      system_prompt: SYSTEM_PROMPT, user_prompt: USER_PROMPT, images: []
    )

    assert_equal ANSWER, text
  end

  test "a rate-limited request tells the visitor to come back later" do
    transport = FakeTransport.new(status: 429, body: '{"error":{"message":"quota"}}')

    error = assert_raises(VintageBrandIdentifier::IdentificationError) do
      provider(transport).generate(system_prompt: SYSTEM_PROMPT, user_prompt: USER_PROMPT, images: [])
    end

    # 無料枠は分単位・日単位の上限に当たるので、利用者には待てば直ると伝える。
    assert_includes error.message, "しばらく経ってから"
  end

  test "a rejected request is reported as a setting problem, not as the visitor's fault" do
    transport = FakeTransport.new(status: 400, body: '{"error":{"message":"bad model"}}')

    error = assert_raises(VintageBrandIdentifier::IdentificationError) do
      provider(transport).generate(system_prompt: SYSTEM_PROMPT, user_prompt: USER_PROMPT, images: [])
    end

    assert_includes error.message, "サイト管理者"
  end

  test "a network failure or an empty answer is retryable, not a 500" do
    [
      FakeTransport.new(error: Timeout::Error.new("timed out")),
      FakeTransport.new(body: "not json at all"),
      FakeTransport.new(body: { output_text: "" }.to_json)
    ].each do |transport|
      assert_raises(VintageBrandIdentifier::IdentificationError) do
        provider(transport).generate(system_prompt: SYSTEM_PROMPT, user_prompt: USER_PROMPT, images: [])
      end
    end
  end

  test "reports itself unconfigured, by name, when no API key is set" do
    unconfigured = VintageBrandIdentifier::GeminiProvider.new(api_key: nil)

    assert_not unconfigured.configured?
    assert_includes unconfigured.missing_key_message, "GEMINI_API_KEY"
    assert VintageBrandIdentifier::GeminiProvider.new(api_key: "key-test").configured?
  end

  private

  def provider(transport)
    VintageBrandIdentifier::GeminiProvider.new(api_key: "key-test", transport: transport)
  end

  def payload(bytes)
    { media_type: "image/png", data: bytes }
  end
end
