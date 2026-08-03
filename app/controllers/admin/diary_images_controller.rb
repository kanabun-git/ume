module Admin
  class DiaryImagesController < BaseController
    def index
      @diary_entries = policy_scope(::DiaryEntry)
                        .includes(:cast, images_attachments: :blob, video_attachment: :blob)
                        .page(params[:page]).per(20)
    end

    def toggle_hidden
      attachment = ActiveStorage::Attachment.where(record_type: "DiaryEntry", name: "images").find(params[:id])
      entry = attachment.record
      authorize entry, :manage_visibility?

      attachment.update!(hidden: !attachment.hidden)
      redirect_to admin_diary_images_path, notice: "画像の公開状態を更新しました。"
    end

    def toggle_video_hidden
      entry = policy_scope(::DiaryEntry).find(params[:id])
      authorize entry, :manage_visibility?

      attachment = entry.video.attachment
      attachment.update!(hidden: !attachment.hidden)
      redirect_to admin_diary_images_path, notice: "動画の公開状態を更新しました。"
    end
  end
end
