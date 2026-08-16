module Admin
  class SettingsController < BaseController
    def edit
      @site_setting = ::SiteSetting.instance
    end

    def update
      @site_setting = ::SiteSetting.instance

      if @site_setting.update(setting_params)
        redirect_to edit_admin_setting_path, notice: "設定を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def setting_params
      attrs = params.require(:site_setting).permit(
        :maintenance_mode, :maintenance_message, :maintenance_image, :maintenance_banner_image
      )
      # A blank file field submits "" for the attachment, which Rails'
      # has_one_attached setter treats as "remove the current file" -- only
      # pass it through when the admin actually chose a new file.
      %i[maintenance_image maintenance_banner_image].each do |name|
        attrs.delete(name) if attrs[name].blank?
      end
      attrs
    end
  end
end
