module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update, :destroy]

    def index
      @users = policy_scope(::User).includes(:shop)
    end

    def show
    end

    def new
      @user = ::User.new
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

    private

    def set_user
      @user = ::User.find(params[:id])
      authorize @user
    end

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :shop_id)
    end
  end
end
