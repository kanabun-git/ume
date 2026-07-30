module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update, :destroy, :issue_account_setup_link]

    def index
      @users = policy_scope(::User).includes(:shop)
    end

    def show
    end

    def new
      # shop_id/role may arrive from a shop's "アカウントを作成する" link
      # (see admin/shops/show) — they only prefill a GET form field, so
      # accepting them outside user_params is safe.
      @user = ::User.new(shop_id: params[:shop_id], role: params[:role])
      authorize @user
    end

    def create
      @user = ::User.new(user_params)
      authorize @user

      if @user.save
        redirect_to admin_users_path, notice: "ユーザーを登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      attrs = user_params
      attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?

      if @user.update(attrs)
        redirect_to admin_users_path, notice: "ユーザー情報を更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.destroy
      redirect_to admin_users_path, notice: "ユーザーを削除しました。"
    end

    # Issues a fresh account-setup link (a Devise password-reset token,
    # reused for this purpose — see User#generate_account_setup_token) and
    # displays it for the admin to copy and send manually; no email is
    # sent by this app.
    def issue_account_setup_link
      raw_token = @user.generate_account_setup_token
      @account_setup_url = edit_user_password_url(reset_password_token: raw_token, host: request.base_url)
    end

    private

    def set_user
      @user = ::User.find(params[:id])
      # issue_account_setup_link authorizes explicitly against :update?,
      # since UserPolicy has no issue_account_setup_link? method for Pundit
      # to infer from the action name.
      if action_name == "issue_account_setup_link"
        authorize @user, :update?
      else
        authorize @user
      end
    end

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :shop_id)
    end
  end
end
