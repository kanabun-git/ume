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
        :maintenance_mode, :maintenance_message,
        :nowprinting_portrait_image, :nowprinting_landscape_image
      )
      attrs.delete(:nowprinting_portrait_image) if attrs[:nowprinting_portrait_image].blank?
      attrs.delete(:nowprinting_landscape_image) if attrs[:nowprinting_landscape_image].blank?
      attrs
    end
  end
end
