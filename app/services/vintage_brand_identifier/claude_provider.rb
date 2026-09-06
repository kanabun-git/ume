class VintageBrandIdentifier
  # Anthropic の Claude で判定を行う。既定はGemini(無料枠)だが、
  # VINTAGE_AI_PROVIDER=claude で切り替えられる -- 判定の精度を上げたく
  # なったときに、費用と引き換えに選べるようにしてある。
  class ClaudeProvider
    MODEL = "claude-opus-5"
    # Opus 5は`thinking`を省略しても適応的思考が有効で、その思考トークンも
    # max_tokensの枠を使う。枠が小さいと回答のJSONが途中で切れるため広めに
    # 取り、費用と待ち時間はeffortを下げて抑える。
    MAX_TOKENS = 8_000
    EFFORT = :low

    def initialize(api_key: ENV["ANTHROPIC_API_KEY"], client: nil)
      @api_key = api_key
      @client = client
    end

    def configured?
      @client.present? || @api_key.present?
    end

    def missing_key_message
      "AI判定が設定されていません(ANTHROPIC_API_KEY 未設定)。サイト管理者にお問い合わせください。"
    end

    # @return [String] モデルが返した本文(JSON文字列のはず)
    def generate(system_prompt:, user_prompt:, images:)
      message = client.messages.create(
        model: MODEL,
        max_tokens: MAX_TOKENS,
        output_config: { effort: EFFORT },
        system_: system_prompt,
        messages: [{ role: "user", content: content_blocks(user_prompt, images) }]
      )

      if message.stop_reason == :max_tokens
        Rails.logger.error("VintageBrandIdentifier Claude hit max_tokens (#{MAX_TOKENS})")
        raise IdentificationError, "判定結果が長すぎて最後まで受け取れませんでした。もう一度お試しください。"
      end

      message.content.select { |block| block.type == :text }.map(&:text).join
    rescue Anthropic::Errors::APIError => e
      Rails.logger.error("VintageBrandIdentifier Claude failed: #{e.class}: #{e.message}")
      raise IdentificationError, "AIとの通信に失敗しました。時間をおいてもう一度お試しください。"
    end

    private

    # 画像は「何枚目か」を示すテキストと交互に並べる(GeminiProviderと同じ理由)。
    def content_blocks(user_prompt, images)
      blocks = []
      images.each_with_index do |image, index|
        blocks << { type: "text", text: "写真#{index + 1}:" }
        blocks << {
          type: "image",
          source: { type: "base64", media_type: image[:media_type], data: Base64.strict_encode64(image[:data]) }
        }
      end
      blocks << { type: "text", text: user_prompt }
    end

    def client
      @client ||= Anthropic::Client.new(api_key: @api_key)
    end
  end
end
