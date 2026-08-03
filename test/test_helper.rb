ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module TestRecords
  # Shared helpers for building the minimal valid graph of records a test
  # needs (Area -> Shop -> Cast -> DiaryEntry, etc.). The app has no
  # fixtures or factory gem, so tests build their own data directly —
  # these just centralize the "what's the minimum required to get a valid
  # Shop/Cast/etc." knowledge in one place instead of every test.
  def create_area(slug: "test-area-#{SecureRandom.hex(4)}", region: "関東", parent: nil)
    Area.create!(slug: slug, name: "テストエリア", region: parent ? nil : region, parent: parent, position: 1)
  end

  def create_genre(slug: "test-genre-#{SecureRandom.hex(4)}")
    Genre.create!(slug: slug, name: "テストジャンル", position: 1)
  end

  def create_plan(name: "テストプラン#{SecureRandom.hex(4)}")
    Plan.create!(name: name, monthly_fee: 0, priority_weight: 1, position: 1)
  end

  def create_shop(**attrs)
    Shop.create!({
      name: "テスト店舗#{SecureRandom.hex(4)}",
      area: create_area,
      genre: create_genre,
      plan: create_plan,
      status: :approved
    }.merge(attrs))
  end

  def create_cast(shop: create_shop, **attrs)
    Cast.create!({
      shop: shop,
      name: "テストキャスト#{SecureRandom.hex(4)}",
      age: 20,
      height: 160,
      bust: 85,
      cup: "C",
      waist: 58,
      hip: 86,
      status: :active
    }.merge(attrs))
  end

  def create_diary_entry(cast: create_cast, **attrs)
    DiaryEntry.create!({
      cast: cast,
      title: "テスト日記",
      body: "テスト本文",
      status: :published,
      published_at: Time.current
    }.merge(attrs))
  end

  def png_upload(filename: "test.png", content_type: "image/png")
    # Smallest possible valid PNG (1x1 transparent pixel), for tests that
    # need a real attachable file without shipping a binary fixture.
    bytes = Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
    )
    { io: StringIO.new(bytes), filename: filename, content_type: content_type }
  end
end

module ActiveSupport
  class TestCase
    include TestRecords
    include ActionMailer::TestHelper

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers

    def create_user(role:, shop: nil, **attrs)
      User.create!({
        email: "user-#{SecureRandom.hex(4)}@example.com",
        password: "password1234",
        password_confirmation: "password1234",
        name: "テストユーザー",
        role: role,
        shop: shop
      }.merge(attrs))
    end
  end
end
