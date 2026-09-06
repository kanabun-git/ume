# 古着の写真(タグ・ラベル・全体)と、利用者が読み取った文字情報から、
# ブランド候補と年代の目安をClaudeに推定させる。
#
# 結果はあくまで参考情報で、真贋や買取価格を保証するものではない --
# その但し書きは画面側(app/views/vintage)にも必ず出している。
class VintageBrandIdentifier
  class IdentificationError < StandardError; end

  MODEL = "claude-opus-5"
  MAX_TOKENS = 2_000

  SYSTEM_PROMPT = <<~PROMPT.freeze
    あなたは古着(ヴィンテージ古着)の買い付け・査定を長年行ってきた鑑定者です。
    利用者が持ち込んだ衣類の写真とメモから、ブランドと製造年代を推定してください。

    判定の作法:
    - ブランドロゴそのものより、首元のブランドタグ・洗濯表示・ユニオンチケット・
      縫製(シングルステッチかどうか)・生産国表記・素材表記といった
      「タグまわりの情報」を根拠にすること
    - 参考情報として渡す年代判定の手がかりを踏まえること
    - 断定できないときは無理に断定せず、候補を複数挙げて確度を下げること
    - 根拠は「なぜそう判断したか」が利用者にも確認できる具体的な記述にすること
      (例:「袖口が1本針のシングルステッチ」「タグにMADE IN USAの表記」)
    - 写っていない・読み取れない情報を、あたかも見えたかのように書かないこと
    - 買取価格や相場の金額は述べないこと(査定額の保証と受け取られるため)
    - 真贋については断定せず、確認すべき点を挙げるにとどめること

    出力は次のキーを持つJSONオブジェクトのみとし、前置き・説明・囲みの記号は
    一切付けないこと。値はすべて日本語で書くこと。

    {
      "item_type": "アイテムの種類(例: デニムジャケット)",
      "brand_candidates": [
        {
          "name": "ブランド名",
          "confidence": "high | medium | low のいずれか",
          "reason": "そのブランドと判断した根拠"
        }
      ],
      "era": "推定年代(例: 1980年代後半〜1990年代前半)",
      "era_reason": "年代をそう推定した根拠",
      "origin": "生産国など分かれば記載",
      "clues": ["写真やメモから読み取れた手がかり"],
      "authenticity_notes": ["真贋・状態について注意して見るべき点"],
      "next_checks": ["判定を絞り込むために追加で撮影・確認するとよい箇所"],
      "summary": "全体の要約(2〜3文)"
    }

    情報が乏しくブランドも年代も推定できない場合は、brand_candidatesを空配列にし、
    next_checksに何を撮れば判定できるようになるかを具体的に書くこと。
  PROMPT

  # @param identification [Vintage::Identification] 入力フォーム
  # @param client [Anthropic::Client, nil] テストから差し替えるためのクライアント
  def initialize(identification:, client: nil)
    @identification = identification
    @injected_client = client
  end

  def call
    if @injected_client.nil? && api_key.blank?
      raise IdentificationError, "AI判定が設定されていません。サイト管理者にお問い合わせください。"
    end

    message = client.messages.create(
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system_: SYSTEM_PROMPT,
      messages: [{ role: "user", content: content_blocks }]
    )

    Vintage::Result.from_text(response_text(message))
  rescue Vintage::Result::ParseError => e
    Rails.logger.error("VintageBrandIdentifier could not parse response: #{e.message}")
    raise IdentificationError, "判定結果をうまく受け取れませんでした。もう一度お試しください。"
  rescue Anthropic::Errors::APIError => e
    Rails.logger.error("VintageBrandIdentifier failed: #{e.class}: #{e.message}")
    raise IdentificationError, "AIとの通信に失敗しました。時間をおいてもう一度お試しください。"
  end

  private

  def response_text(message)
    message.content.select { |block| block.type == :text }.map(&:text).join
  end

  # 画像は「何枚目か」を示すテキストと交互に並べる。複数枚を渡したとき、
  # どの写真の話をしているのかが回答の根拠に書けるようにするため。
  def content_blocks
    blocks = []
    image_payloads.each_with_index do |payload, index|
      blocks << { type: "text", text: "写真#{index + 1}:" }
      blocks << {
        type: "image",
        source: {
          type: "base64",
          media_type: payload[:media_type],
          data: Base64.strict_encode64(payload[:data])
        }
      }
    end
    blocks << { type: "text", text: user_prompt }
    blocks
  end

  def user_prompt
    <<~PROMPT
      # 年代判定の参考情報
      #{Vintage::BrandGuide.reference_text}

      # 判定してほしいアイテム
      種類: #{@identification.item_type.presence || "(未選択)"}
      写真: #{image_payloads.size}枚
      利用者のメモ(タグの表記など):
      #{@identification.notes.presence || "(記入なし)"}

      上記をもとに、指定のJSON形式でブランドと年代を推定してください。
    PROMPT
  end

  # アップロードされたファイルは一度読んだら読み直しになるので、
  # プロンプトと画像ブロックの両方から使えるよう1度だけ取り出す。
  def image_payloads
    @image_payloads ||= @identification.image_payloads
  end

  def client
    @client ||= @injected_client || Anthropic::Client.new(api_key: api_key)
  end

  def api_key
    ENV["ANTHROPIC_API_KEY"]
  end
end
