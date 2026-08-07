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

    def import
      authorize ::Genre.new, :import?

      if params[:file].blank?
        redirect_to admin_genres_path, alert: "CSVファイルを選択してください。"
        return
      end

      result = ::GenreImport.call(params[:file])
      redirect_to admin_genres_path, notice: import_notice(result)
    end

    def template
      authorize ::Genre.new, :import?
      send_data ::GenreImport::TEMPLATE_CSV, filename: "genres_template.csv", type: "text/csv"
    end

    def export
      authorize ::Genre.new, :export?
      send_data ::GenreImport.export(policy_scope(::Genre)), filename: "genres_#{Date.current}.csv", type: "text/csv"
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
