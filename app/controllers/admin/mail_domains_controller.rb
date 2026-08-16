module Admin
  # 運営管理画面 > メールアドレス管理 の入口。#index が「サイト(ドメイン)ごとに
  # メールアドレスを追加・削除・送信テストする」1画面そのもので、
  # 個々のアドレス側の操作は Admin::MailAccountsController が受け持つ。
  class MailDomainsController < BaseController
    include MailboxManagement

    before_action :set_mail_domain, only: [:edit, :update, :destroy]

    def index
      load_mailbox_index
    end

    def create
      @mail_domain = ::MailDomain.new(mail_domain_params)
      authorize @mail_domain

      if @mail_domain.save
        sync_mailboxes("サイトを登録しました。")
        redirect_to admin_mail_domains_path
      else
        load_mailbox_index
        render :index, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @mail_domain.update(mail_domain_params)
        sync_mailboxes("サイトを更新しました。")
        redirect_to admin_mail_domains_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      count = @mail_domain.mail_accounts.count
      @mail_domain.destroy

      notice = if count.positive?
        "サイトと、そのサイトのメールアドレス#{count}件を削除しました。"
      else
        "サイトを削除しました。"
      end
      sync_mailboxes(notice)
      redirect_to admin_mail_domains_path
    end

    private

    def set_mail_domain
      @mail_domain = ::MailDomain.find(params[:id])
      authorize @mail_domain
    end

    def mail_domain_params
      params.require(:mail_domain).permit(:name, :domain, :mail_server_host, :note)
    end
  end
end
