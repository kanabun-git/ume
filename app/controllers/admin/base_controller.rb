module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_platform_admin_role!
    layout "admin"

    private

    def require_platform_admin_role!
      return if current_user.platform_admin?

      flash[:alert] = "運営者専用のページです。"
      redirect_to root_path
    end

    # Shared flash message for the master-data CSV import actions
    # (genres/areas/plans/member_ranks) -- built from an
    # AdminCsvImport::Result.
    def import_notice(result)
      notice = "#{result.created_count}件登録しました。"
      if result.error_rows.any?
        notice += "(#{result.error_rows.size}件はエラーのためスキップしました。1行目はヘッダー行です: " \
          "#{result.error_rows.map { |r| "#{r[:line]}行目(#{r[:errors]})" }.join("、")})"
      end
      notice
    end
  end
end
