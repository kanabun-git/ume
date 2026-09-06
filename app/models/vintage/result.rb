module Vintage
  # VintageBrandIdentifierが受け取ったClaudeの回答(JSON)を、ビューが
  # そのまま描ける形に整えた値オブジェクト。
  #
  # 回答は生成物なので、キーが欠けていたり型が違ったりしても画面が落ちない
  # ことを最優先にしている(足りない項目はそのセクションごと表示しない)。
  class Result
    class ParseError < StandardError; end

    CONFIDENCE_LABELS = { "high" => "高い", "medium" => "中くらい", "low" => "低い" }.freeze

    BrandCandidate = Struct.new(:name, :confidence, :reason, keyword_init: true) do
      def confidence_label
        CONFIDENCE_LABELS.fetch(confidence.to_s, "不明")
      end

      # ガイドページ(/vintage/guide)に該当ブランドの解説があればアンカーを返す。
      # ブランド名は「Levi's(リーバイス)」のような表記ゆれで返ってくるので、
      # 英字部分の部分一致で照合する。
      def guide_slug
        normalized = name.to_s.downcase
        brand = Vintage::BrandGuide::BRANDS.find do |candidate|
          key = candidate[:name].split("(").first.to_s.downcase.strip
          key.present? && (normalized.include?(key) || key.include?(normalized))
        end
        brand&.dig(:slug)
      end
    end

    attr_reader :item_type, :brand_candidates, :era, :era_reason, :origin,
                :clues, :authenticity_notes, :next_checks, :summary

    def self.from_text(text)
      raise ParseError, "回答が空でした。" if text.blank?

      new(JSON.parse(strip_code_fence(text)))
    rescue JSON::ParserError => e
      raise ParseError, "回答を解釈できませんでした: #{e.message}"
    end

    # Claudeは指示しても ```json ... ``` で囲って返すことがあるので、
    # 囲みが付いていれば外してから解釈する。
    def self.strip_code_fence(text)
      stripped = text.strip
      return stripped unless stripped.start_with?("```")

      stripped.sub(/\A```[a-zA-Z]*\n/, "").sub(/```\z/, "").strip
    end

    def initialize(payload)
      raise ParseError, "回答の形式が想定と違いました。" unless payload.is_a?(Hash)

      @item_type = presence_of(payload["item_type"])
      @era = presence_of(payload["era"])
      @era_reason = presence_of(payload["era_reason"])
      @origin = presence_of(payload["origin"])
      @summary = presence_of(payload["summary"])
      @clues = string_list(payload["clues"])
      @authenticity_notes = string_list(payload["authenticity_notes"])
      @next_checks = string_list(payload["next_checks"])
      @brand_candidates = build_candidates(payload["brand_candidates"])
    end

    # 写真もメモも手がかりにならず、ブランドも年代も出せなかった場合。
    # 画面は「判定できませんでした」の案内に切り替える。
    def empty?
      brand_candidates.empty? && era.blank? && summary.blank?
    end

    private

    def build_candidates(raw)
      Array(raw).filter_map do |candidate|
        next unless candidate.is_a?(Hash)
        name = presence_of(candidate["name"])
        next if name.blank?

        BrandCandidate.new(
          name: name,
          confidence: presence_of(candidate["confidence"]),
          reason: presence_of(candidate["reason"])
        )
      end
    end

    def string_list(raw)
      Array(raw).filter_map { |value| presence_of(value) }
    end

    def presence_of(value)
      value.is_a?(String) ? value.strip.presence : nil
    end
  end
end
