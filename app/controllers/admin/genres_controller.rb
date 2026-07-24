module Admin
  class GenresController < BaseController
    before_action :set_genre, only: [:show, :edit, :update, :destroy]

    def index
      @genres = policy_scope(::Genre)
    end

    def show
    end

    def new
      @genre = ::Genre.new
      authorize @genre
    end

    def create
      @genre = ::Genre.new(genre_params)
      authorize @genre

      if @genre.save
        redirect_to admin_genres_path, notice: "ジャンルを登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @genre.update(genre_params)
        redirect_to admin_genres_path, notice: "ジャンルを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @genre.destroy
      redirect_to admin_genres_path, notice: "ジャンルを削除しました。"
    end

    private

    def set_genre
      @genre = ::Genre.find(params[:id])
      authorize @genre
    end

    def genre_params
      params.require(:genre).permit(:name, :slug, :position)
    end
  end
end
