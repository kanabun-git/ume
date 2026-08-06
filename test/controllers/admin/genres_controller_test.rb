require "test_helper"

module Admin
  class GenresControllerTest < ActionDispatch::IntegrationTest
    test "a platform admin can create, update, and delete a genre" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      post admin_genres_path, params: { genre: { name: "ソープ", slug: "soap" } }
      assert_redirected_to admin_genres_path
      genre = Genre.find_by(name: "ソープ")
      assert genre.present?

      patch admin_genre_path(genre.id), params: { genre: { name: "ヘルス" } }
      assert_equal "ヘルス", genre.reload.name

      delete admin_genre_path(genre.id)
      assert_not Genre.exists?(genre.id)
    end

    test "a shop admin cannot access genre management" do
      user = create_user(role: :shop_admin, shop: create_shop)
      sign_in user

      get admin_genres_path

      assert_redirected_to root_path
    end

    test "import creates genres from an uploaded CSV" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      csv = <<~CSV
        名前,スラッグ,表示順
        インポートジャンル,imported-genre,1
      CSV
      file = Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "genres.csv")

      post import_admin_genres_path, params: { file: file }

      assert_redirected_to admin_genres_path
      assert Genre.exists?(name: "インポートジャンル")
    end

    test "template downloads a CSV with the expected headers" do
      admin = create_user(role: :platform_admin)
      sign_in admin

      get template_admin_genres_path

      assert_response :success
      assert_match "スラッグ", response.body
    end
  end
end
