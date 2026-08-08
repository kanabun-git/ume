module Admin
  # All the site's swappable base images (placeholders, logo, moderation
  # replacement images, Index page images, member card design) in one
  # place, separate from Admin::SettingsController's operational toggles
  # (maintenance mode) so "where do I upload a base image" has one answer.
  class BasicSettingsController < BaseController
    def edit
      @site_setting = ::SiteSetting.instance
    end

    def update
      @site_setting = ::SiteSetting.instance

      if @site_setting.update(basic_setting_params)
        redirect_to edit_admin_basic_setting_path, notice: "画像を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def basic_setting_params
      attrs = params.require(:site_setting).permit(*::SiteSetting::IMAGE_ATTACHMENTS)
      # A blank file field submits "" for the attachment, which Rails'
      # has_one_attached setter treats as "remove the current file" -- only
      # pass it through when the admin actually chose a new file.
      ::SiteSetting::IMAGE_ATTACHMENTS.each do |name|
        attrs.delete(name) if attrs[name].blank?
      end
      attrs
    end
  end
end
