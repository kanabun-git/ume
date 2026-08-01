module CastPortal
  class DiaryEntriesController < BaseController
    before_action :set_diary_entry, only: [:show, :edit, :update, :destroy]

    def index
      @diary_entries = policy_scope(::DiaryEntry)
    end

    def show
    end

    def new
      @diary_entry = current_cast_profile.diary_entries.build
      authorize @diary_entry
    end

    def create
      @diary_entry = current_cast_profile.diary_entries.build(diary_entry_params)
      authorize @diary_entry

      if @diary_entry.save
        redirect_to cast_diary_entries_path, notice: "日記を投稿しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = diary_entry_params.except(:images)
      # A file_field with no new selection submits an empty string, and
      # assigning that to a has_one_attached setter purges the existing
      # attachment — so leave :video out entirely unless a file was chosen.
      attrs = attrs.except(:video) if diary_entry_params[:video].blank?

      if update_with_appended_images(@diary_entry, attachment_name: :images, new_files: diary_entry_params[:images], other_attrs: attrs)
        redirect_to cast_diary_entries_path, notice: "日記を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @diary_entry.destroy
      redirect_to cast_diary_entries_path, notice: "日記を削除しました。"
    end

    # Returns an AI-drafted body for the diary form to fill in. The cast
    # always reviews/edits before saving — nothing is persisted here.
    def generate_draft
      authorize ::DiaryEntry.new(cast: current_cast_profile), :create?

      # `::`-prefixed: inside `module CastPortal` a bare constant would be
      # looked up as CastPortal::DiaryDraftGenerator and fail.
      body = ::DiaryDraftGenerator.new(
        cast: current_cast_profile,
        instruction: params[:instruction]
      ).call

      render json: { body: body }
    rescue ::DiaryDraftGenerator::GenerationError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def set_diary_entry
      @diary_entry = policy_scope(::DiaryEntry).find(params[:id])
      authorize @diary_entry
    end

    def diary_entry_params
      params.require(:diary_entry).permit(:title, :body, :status, :published_at, :video, images: [])
    end
  end
end
