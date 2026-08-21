module Admin
  # Lets a platform admin freely rewrite ShopProspectMailer#outreach_email's
  # wording (see 営業先候補管理 > 営業メール文面の編集) without a deploy. No
  # Pundit policy here -- like Admin::SettingsController, Admin::BaseController's
  # require_platform_admin_role! already gates the whole namespace.
  class OutreachEmailTemplatesController < BaseController
    def edit
      @outreach_email_template = ::OutreachEmailTemplate.instance
    end

    def update
      @outreach_email_template = ::OutreachEmailTemplate.instance

      if @outreach_email_template.update(template_params)
        redirect_to edit_admin_outreach_email_template_path, notice: "営業メールの文面を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def template_params
      params.require(:outreach_email_template).permit(:subject, :body)
    end
  end
end
