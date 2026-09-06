module Vintage
  # 古着ブランド判定ツールのフォームオブジェクト。Corporate::Inquiryと同じく
  # 保存も管理画面もないので、ActiveRecordではなくプレーンなActiveModel。
  #
  # 送られた写真はディスクにもActive Storageにも保存しない。判定のために
  # そのリクエストの中でClaudeへ渡すだけで、レスポンスを返したら破棄する
  # (他人の服の写真を預かり続ける必要がないため)。
  class Identification
    include ActiveModel::Model
    include ActiveModel::Attributes

    MAX_IMAGES = 4
    MAX_IMAGE_SIZE = 5.megabytes
    PERMITTED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif"].freeze
    MAX_NOTES_LENGTH = 1_000

    ITEM_TYPES = [
      "Tシャツ・カットソー", "スウェット・パーカー", "シャツ・ブラウス",
      "デニム・パンツ", "ジャケット・アウター", "ニット", "帽子・小物", "その他"
    ].freeze

    # 中古相場は状態で大きく変わるので、フリマアプリの出品と同じ粒度で
    # 利用者に選んでもらう(未選択なら「並」相当として推定させる)。
    CONDITIONS = [
      "未使用・未使用に近い",
      "目立った傷や汚れなし",
      "やや傷や汚れあり",
      "傷や汚れあり",
      "全体的に状態が悪い(ダメージ・リペアあり)"
    ].freeze

    MAX_SIZE_NOTE_LENGTH = 100

    # AIへの問い合わせは1件ごとに費用と待ち時間が発生するので、
    # Corporate::Inquiryの単発クールダウンに加えて時間あたりの上限も設ける。
    # 判定は何枚か撮り直して試すものなので、クールダウン自体は短くしてある。
    COOLDOWN = 10.seconds
    RATE_WINDOW = 1.hour
    WINDOW_LIMIT = 20

    attribute :notes, :string
    attribute :item_type, :string
    attribute :condition, :string
    attribute :size_note, :string
    attr_accessor :images, :ip_address

    validates :item_type, inclusion: { in: ITEM_TYPES, allow_blank: true }
    validates :condition, inclusion: { in: CONDITIONS, allow_blank: true }
    validates :notes, length: { maximum: MAX_NOTES_LENGTH }
    validates :size_note, length: { maximum: MAX_SIZE_NOTE_LENGTH }
    validate :images_present_or_notes
    validate :images_within_limits
    validate :rate_limit

    def initialize(attributes = {})
      super
      @images = Array(@images).reject { |image| image.blank? }
    end

    # 判定結果を受け取ったあとに呼ぶ。次のリクエストをクールダウンが
    # 明けるまで、また1時間あたりの上限まで、それぞれ止めるためのカウンタ。
    def record_request!
      return if ip_address.blank?

      Rails.cache.write(self.class.cooldown_cache_key(ip_address), true, expires_in: COOLDOWN)
      # 単純なカウンタではなく実行時刻の配列を持つ。どのキャッシュストアでも
      # 同じ挙動になり(incrementのraw指定や有効期限の引き継ぎに依存しない)、
      # 1時間の枠が使い続けている人の分だけ延び続けることもない。
      Rails.cache.write(
        self.class.hourly_cache_key(ip_address),
        recent_request_times + [Time.current],
        expires_in: RATE_WINDOW
      )
    end

    def self.cooldown_cache_key(ip_address)
      "vintage_identification_cooldown/#{ip_address}"
    end

    def self.hourly_cache_key(ip_address)
      "vintage_identification_hourly/#{ip_address}"
    end

    # VintageBrandIdentifierへ渡す形。サービス側がアップロード由来の
    # オブジェクト(ActionDispatch::Http::UploadedFile)を知らずに済むよう、
    # ここでバイト列とMIMEタイプだけに落とす。
    def image_payloads
      images.map do |image|
        image.rewind if image.respond_to?(:rewind)
        { media_type: image.content_type.to_s.split(";").first, data: image.read }
      end
    end

    private

    def images_present_or_notes
      return if images.any? || notes.present?

      errors.add(:base, "写真をアップロードするか、タグに書かれている内容を入力してください。")
    end

    def images_within_limits
      if images.size > MAX_IMAGES
        errors.add(:images, "は#{MAX_IMAGES}枚までアップロードできます。")
      end

      images.each do |image|
        unless PERMITTED_IMAGE_TYPES.include?(image.content_type.to_s.split(";").first)
          errors.add(:images, "はJPEG・PNG・WebP・GIF形式のみ対応しています。")
          break
        end
      end

      if images.any? { |image| image.size > MAX_IMAGE_SIZE }
        errors.add(:images, "は1枚あたり#{MAX_IMAGE_SIZE / 1.megabyte}MBまでです。")
      end
    end

    def rate_limit
      return if ip_address.blank?

      if Rails.cache.exist?(self.class.cooldown_cache_key(ip_address))
        errors.add(:base, "判定の間隔が短すぎます。少し待ってからもう一度お試しください。")
      elsif recent_request_times.size >= WINDOW_LIMIT
        errors.add(:base, "判定回数の上限に達しました。しばらく経ってからもう一度お試しください。")
      end
    end

    def recent_request_times
      Array(Rails.cache.read(self.class.hourly_cache_key(ip_address)))
        .select { |time| time > RATE_WINDOW.ago }
    end
  end
end
