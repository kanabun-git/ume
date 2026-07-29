module CastPortal
  class ProfilesController < BaseController
    before_action :set_cast

    def edit
      authorize @cast, :update_profile?
    end

    def update
      authorize @cast, :update_profile?
      attrs = cast_params.except(:photos)

      if update_with_appended_images(@cast, attachment_name: :photos, new_files: cast_params[:photos], other_attrs: attrs)
        redirect_to cast_root_path, notice: "プロフィールを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_cast
      @cast = current_cast_profile
      redirect_to cast_root_path, alert: "プロフィールが未登録です。店舗管理者にお問い合わせください。" if @cast.nil?
    end

    def cast_params
      params.require(:cast).permit(
        :catch_copy, :description, :height, :bust, :waist, :hip, :cup,
        :appeal_comment, :selling_points, :qa_message, :zodiac_sign, :blood_type,
        photos: []
      )
    end
  end
end
