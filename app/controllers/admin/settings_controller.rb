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
      params.require(:site_setting).permit(:maintenance_mode, :maintenance_message)
    end
  end
end
