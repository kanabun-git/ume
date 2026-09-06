require "test_helper"

module Vintage
  class IdentificationTest < ActiveSupport::TestCase
    test "needs either a photo or written notes" do
      identification = Vintage::Identification.new

      assert_not identification.valid?
      assert_includes identification.errors.full_messages.join, "写真をアップロードするか"
    end

    test "notes alone are enough to run a judgement" do
      assert Vintage::Identification.new(notes: "タグにMADE IN USA、袖はシングルステッチ").valid?
    end

    test "rejects more photos than the upload limit" do
      images = Array.new(Vintage::Identification::MAX_IMAGES + 1) { uploaded_png }

      identification = Vintage::Identification.new(images: images)

      assert_not identification.valid?
      assert_includes identification.errors.full_messages.join, "#{Vintage::Identification::MAX_IMAGES}枚まで"
    end

    test "rejects a file that is not an image" do
      pdf = ActionDispatch::Http::UploadedFile.new(
        tempfile: Tempfile.new("tag"), filename: "tag.pdf", type: "application/pdf"
      )

      identification = Vintage::Identification.new(images: [pdf])

      assert_not identification.valid?
      assert_includes identification.errors.full_messages.join, "JPEG"
    end

    test "rejects an image over the size limit" do
      oversized = uploaded_png(bytes: "x" * (Vintage::Identification::MAX_IMAGE_SIZE + 1))

      identification = Vintage::Identification.new(images: [oversized])

      assert_not identification.valid?
      assert_includes identification.errors.full_messages.join, "MBまで"
    end

    test "blank file field entries are dropped rather than counted as photos" do
      # A file_field with nothing selected submits an empty string.
      identification = Vintage::Identification.new(images: [""], notes: "タグ表記あり")

      assert_empty identification.images
      assert identification.valid?
    end

    test "image payloads hand the service bytes and a bare media type" do
      identification = Vintage::Identification.new(images: [uploaded_png(bytes: "PNGDATA")])

      payload = identification.image_payloads.first

      assert_equal "image/png", payload[:media_type]
      assert_equal "PNGDATA", payload[:data]
    end

    test "a second judgement from the same IP inside the cooldown is rejected" do
      with_real_cache do
        first = Vintage::Identification.new(notes: "1回目", ip_address: "203.0.113.5")
        assert first.valid?
        first.record_request!

        second = Vintage::Identification.new(notes: "2回目", ip_address: "203.0.113.5")

        assert_not second.valid?
        assert_includes second.errors.full_messages.join, "判定の間隔が短すぎます"
      end
    end

    test "a judgement after the cooldown has passed is allowed again" do
      with_real_cache do
        Vintage::Identification.new(notes: "1回目", ip_address: "203.0.113.5").record_request!

        travel Vintage::Identification::COOLDOWN + 1.second

        assert Vintage::Identification.new(notes: "2回目", ip_address: "203.0.113.5").valid?
      end
    end

    test "the hourly window blocks a run once the limit is reached, and frees up as it slides" do
      with_real_cache do
        ip = "203.0.113.9"
        Vintage::Identification::WINDOW_LIMIT.times do |i|
          identification = Vintage::Identification.new(notes: "#{i}回目", ip_address: ip)
          identification.record_request!
          travel Vintage::Identification::COOLDOWN + 1.second
        end

        blocked = Vintage::Identification.new(notes: "上限超え", ip_address: ip)
        assert_not blocked.valid?
        assert_includes blocked.errors.full_messages.join, "上限に達しました"

        travel Vintage::Identification::RATE_WINDOW + 1.second
        assert Vintage::Identification.new(notes: "枠が空いた後", ip_address: ip).valid?
      end
    end

    test "requests from other IPs are counted separately" do
      with_real_cache do
        Vintage::Identification.new(notes: "1回目", ip_address: "203.0.113.5").record_request!

        assert Vintage::Identification.new(notes: "別の人", ip_address: "198.51.100.7").valid?
      end
    end

    private

    def uploaded_png(bytes: "fake png bytes", filename: "tag.png", type: "image/png")
      tempfile = Tempfile.new(["tag", ".png"])
      tempfile.binmode
      tempfile.write(bytes)
      tempfile.rewind
      ActionDispatch::Http::UploadedFile.new(tempfile: tempfile, filename: filename, type: type)
    end

    # 判定回数の制限はRails.cacheに乗っているが、テスト環境は :null_store で
    # 全てのキャッシュ操作が握り潰される(Corporate::Inquiryのテストと同じ事情)。
    # 制限そのものを試すテストの間だけ、実際に動くストアに差し替える。
    def with_real_cache
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      yield
    ensure
      Rails.cache = original_cache
    end
  end
end
