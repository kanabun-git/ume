# Drafts a diary entry for a cast in that cast's own writing style, by
# showing Claude the cast's past entries as style reference alongside a
# short instruction describing what today's entry should be about.
#
# The cast always reviews and edits the draft before it is saved — this
# fills the form field, it does not post anything.
class DiaryDraftGenerator
  class GenerationError < StandardError; end

  MODEL = "claude-opus-5"
  MAX_TOKENS = 2_000
  # How many past entries to show as style reference. Enough to establish a
  # voice without pushing the request cost up for a short piece of writing.
  SAMPLE_SIZE = 8

  SYSTEM_PROMPT = <<~PROMPT.freeze
    あなたは日本の風俗店ポータルサイトに在籍するキャストの、写メ日記の下書きを手伝うアシスタントです。

    渡された「過去の日記」はすべて、これから下書きを書く本人が書いたものです。
    その人の口調・語尾・絵文字や記号の使い方・改行の入れ方・一文の長さといった
    書き癖を丁寧に読み取り、本人が書いたと感じられる文章を作成してください。

    ルール:
    - 過去の日記の内容をそのまま繰り返さず、指示された話題で新しく書くこと
    - 性的に露骨な表現、サービス内容の直接的な描写は書かないこと
      (公開される宣伝用のブログとして適切な範囲にとどめる)
    - 実在の人物名、店舗の連絡先、住所などの個人情報は書かないこと
    - 本文のみを出力し、「はい、書きました」等の前置きや説明、
      タイトル、囲みの記号は一切付けないこと
    - 過去の日記が1件も無い場合は、明るく親しみやすい標準的な口調で書くこと
  PROMPT

  def initialize(cast:, instruction:)
    @cast = cast
    @instruction = instruction.to_s.strip
  end

  def call
    raise GenerationError, "どんな日記を書きたいか入力してください。" if @instruction.blank?
    raise GenerationError, "AI機能が設定されていません。管理者にお問い合わせください。" if api_key.blank?

    message = client.messages.create(
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system_: SYSTEM_PROMPT,
      messages: [{ role: "user", content: user_prompt }]
    )

    text = message.content.select { |block| block.type == :text }.map(&:text).join.strip
    raise GenerationError, "下書きを生成できませんでした。もう一度お試しください。" if text.blank?

    text
  rescue Anthropic::Errors::APIError => e
    Rails.logger.error("DiaryDraftGenerator failed: #{e.class}: #{e.message}")
    raise GenerationError, "AIとの通信に失敗しました。時間をおいてもう一度お試しください。"
  end

  private

  def user_prompt
    <<~PROMPT
      # 過去の日記(書き癖の参考。内容は真似しないこと)
      #{past_entries_text}

      # 今回書きたい日記の内容
      #{@instruction}

      上記の指示に沿って、この人の書き癖で日記の本文を書いてください。
    PROMPT
  end

  def past_entries_text
    entries = @cast.diary_entries.order(created_at: :desc).limit(SAMPLE_SIZE)
    return "(過去の日記はまだありません)" if entries.empty?

    entries.map { |entry| "---\nタイトル: #{entry.title}\n#{entry.body}" }.join("\n")
  end

  def client
    @client ||= Anthropic::Client.new(api_key: api_key)
  end

  def api_key
    ENV["ANTHROPIC_API_KEY"]
  end
end
