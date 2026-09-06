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

    # 金額の範囲(中古相場・新品時の定価)。日本円の整数で持ち、片方しか
    # 答えが無い場合(「10,000円以上」など)も落とさずに表示できるようにしてある。
    PriceRange = Struct.new(:low, :high, :note, :factors, keyword_init: true) do
      def range_label
        return "#{number_with_delimiter(low)}円 〜 #{number_with_delimiter(high)}円" if low && high
        return "#{number_with_delimiter(low)}円 〜" if low
        return "〜 #{number_with_delimiter(high)}円" if high

        nil
      end

      def present?
        range_label.present?
      end

      private

      def number_with_delimiter(value)
        ActiveSupport::NumberHelper.number_to_delimited(value)
      end
    end

    attr_reader :item_type, :brand_candidates, :era, :era_reason, :origin,
                :clues, :authenticity_notes, :next_checks, :summary,
                :market_price, :original_price, :target_gender, :target_age, :target_age_reason

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
      @target_gender = presence_of(payload["target_gender"])
      @target_age = presence_of(payload["target_age"])
      @target_age_reason = presence_of(payload["target_age_reason"])
      @clues = string_list(payload["clues"])
      @authenticity_notes = string_list(payload["authenticity_notes"])
      @next_checks = string_list(payload["next_checks"])
      @brand_candidates = build_candidates(payload["brand_candidates"])
      @market_price = build_price(payload["market_price"])
      @original_price = build_price(payload["original_price"])
    end

    # 相場の実売価格を利用者が自分で確かめられるよう、検索に使える語を組み立てる。
    # AIの見積もりだけを鵜呑みにさせないための導線なので、ブランドが特定
    # できていないときは何も返さない。
    def market_search_keyword
      brand = brand_candidates.first&.name
      return nil if brand.blank?

      # 「Levi's(リーバイス)」のような表記から、検索に効く英字部分だけを取る。
      [brand.split("(").first.to_s.strip, item_type].compact_blank.join(" ")
    end

    # 写真もメモも手がかりにならず、ブランドも年代も出せなかった場合。
    # 画面は「判定できませんでした」の案内に切り替える。
    def empty?
      brand_candidates.empty? && era.blank? && summary.blank?
    end

    private

    def build_price(raw)
      return nil unless raw.is_a?(Hash)

      price = PriceRange.new(
        low: yen(raw["low"]),
        high: yen(raw["high"]),
        note: presence_of(raw["note"]),
        factors: string_list(raw["factors"])
      )
      price.present? ? price : nil
    end

    # 金額は数値で返すよう指示しているが、"8,000円" や "8,000〜15,000円" の
    # ような文字列で返ってくることもある。最初に現れた数字だけを拾うことで、
    # 後者を「80,001,5000円」のような桁違いの値にしてしまわないようにする。
    def yen(value)
      case value
      when Numeric then value.to_i.positive? ? value.to_i : nil
      when String then value[/[0-9][0-9,]*/]&.delete(",")&.to_i
      end
    end

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
