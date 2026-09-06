class VintageBrandIdentifier
  # Google の Gemini API(Interactions API)で判定を行う。
  #
  # 無料枠のあるモデルを既定にしてあるので、費用をかけずに運用できる。
  # ただし無料枠では送信内容がGoogleのサービス改善に利用され得るため、
  # その旨を画面にも明記している(VintageBrandIdentifier::PRIVACY_NOTICE)。
  #
  # 公式SDK(Ruby)は無いのでRESTを直接叩く。Net::HTTPで足りる範囲なので、
  # 依存gemは増やしていない。
  class GeminiProvider
    DEFAULT_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/interactions".freeze
    # APIのバージョンが上がったときや、動作確認でスタブへ向けたいときに
    # デプロイなしで差し替えられるようにしてある(通常は未設定でよい)。
    def self.endpoint
      URI(ENV["GEMINI_API_ENDPOINT"].presence || DEFAULT_ENDPOINT)
    end
    # 無料枠で使えるモデルはアカウントによって変わる。実際に使える組み合わせは
    # Google AI Studio のRate limitsページで確認でき、変更はGEMINI_MODELの
    # 環境変数だけで済む。
    DEFAULT_MODEL = "gemini-3.5-flash".freeze
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 120

    # 実際にHTTPを話す既定の実装。テストからはこれを差し替える。
    class HttpTransport
      def call(payload)
        endpoint = GeminiProvider.endpoint
        request = Net::HTTP::Post.new(endpoint)
        request["Content-Type"] = "application/json"
        request["x-goog-api-key"] = payload[:api_key]
        request.body = payload[:body]

        response = Net::HTTP.start(
          endpoint.hostname, endpoint.port,
          use_ssl: endpoint.scheme == "https", open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT
        ) { |http| http.request(request) }

        [response.code.to_i, response.body]
      end
    end

    def initialize(api_key: ENV["GEMINI_API_KEY"], model: nil, transport: nil)
      @api_key = api_key
      @model = model.presence || ENV["GEMINI_MODEL"].presence || DEFAULT_MODEL
      @transport = transport
    end

    def configured?
      @api_key.present?
    end

    def missing_key_message
      "AI判定が設定されていません(GEMINI_API_KEY 未設定)。サイト管理者にお問い合わせください。"
    end

    # @return [String] モデルが返した本文(JSON文字列のはず)
    def generate(system_prompt:, user_prompt:, images:)
      status, body = transport.call(api_key: @api_key, body: request_body(system_prompt, user_prompt, images).to_json)

      unless status == 200
        Rails.logger.error("VintageBrandIdentifier Gemini returned #{status}: #{body.to_s.truncate(500)}")
        raise IdentificationError, error_message_for(status)
      end

      extract_text(body)
    rescue JSON::ParserError, Timeout::Error, SystemCallError, IOError, OpenSSL::SSL::SSLError => e
      Rails.logger.error("VintageBrandIdentifier Gemini failed: #{e.class}: #{e.message}")
      raise IdentificationError, "AIとの通信に失敗しました。時間をおいてもう一度お試しください。"
    end

    private

    def transport
      @transport ||= HttpTransport.new
    end

    # 画像は「何枚目か」を示すテキストと交互に並べる。複数枚を渡したとき、
    # どの写真の話をしているのかが回答の根拠に書けるようにするため。
    def request_body(system_prompt, user_prompt, images)
      input = []
      images.each_with_index do |image, index|
        input << { type: "text", text: "写真#{index + 1}:" }
        input << { type: "image", mime_type: image[:media_type], data: Base64.strict_encode64(image[:data]) }
      end
      input << { type: "text", text: user_prompt }

      {
        model: @model,
        system_instruction: system_prompt,
        input: input,
        # JSONで返すことを型で縛る。プロンプトでの指示だけに頼らずに済む。
        response_format: { type: "text", mime_type: "application/json" }
      }
    end

    def extract_text(body)
      payload = JSON.parse(body)
      text = payload["output_text"].presence || text_from_steps(payload)
      return text if text.present?

      Rails.logger.error("VintageBrandIdentifier Gemini returned no text: #{body.to_s.truncate(500)}")
      raise IdentificationError, "判定結果を受け取れませんでした。もう一度お試しください。"
    end

    # output_text が無い形で返ってきた場合の取りこぼし防止。
    def text_from_steps(payload)
      Array(payload["steps"]).flat_map { |step| Array(step["content"]) }
        .select { |block| block["type"] == "text" }
        .map { |block| block["text"] }
        .join
    end

    def error_message_for(status)
      case status
      when 429 then "判定の利用が混み合っています。しばらく経ってからもう一度お試しください。"
      when 400..499 then "AI判定の設定に問題があります。サイト管理者にお問い合わせください。"
      else "AIとの通信に失敗しました。時間をおいてもう一度お試しください。"
      end
    end
  end
end
