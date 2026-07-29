module Admin
  class CastImagesController < BaseController
    def index
      @casts = policy_scope(::Cast).includes(photos_attachments: :blob).order(:shop_id, :name).page(params[:page]).per(20)
    end

    def toggle_hidden
      attachment = ActiveStorage::Attachment.where(record_type: "Cast", name: "photos").find(params[:id])
      cast = attachment.record
      authorize cast, :manage_visibility?

      attachment.update!(hidden: !attachment.hidden)
      redirect_to admin_cast_images_path, notice: "画像の公開状態を更新しました。"
    end
  end
end
