module MailAdmin
  # 受信箱を見る: メールアドレス管理画面から、そのアドレスのINBOXを
  # 読み取り専用で閲覧する(MailboxInbox参照)。作成・返信・削除はしない。
  class MailAccountMessagesController < BaseController
    before_action :set_mail_account

    def index
      @messages = ::MailboxInbox.new(@mail_account).messages
    rescue ::MailboxInbox::ConnectionError => e
      @error = e.message
      @messages = []
    end

    def show
      @message = ::MailboxInbox.new(@mail_account).message(params[:id].to_i)
    rescue ::MailboxInbox::ConnectionError => e
      redirect_to mail_admin_mail_account_messages_path(@mail_account), alert: e.message
    end

    private

    def set_mail_account
      @mail_account = ::MailAccount.find(params[:mail_account_id])
    end
  end
end
