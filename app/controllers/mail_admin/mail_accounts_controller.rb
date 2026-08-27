module MailAdmin
  # The per-address half of the mail address management screen: add an
  # address to a site, delete one, send a test mail from it, and re-run the
  # mail server sync by hand after a failure. Every action renders/redirects
  # back to MailAdmin::MailDomainsController#index, which is the whole screen.
  class MailAccountsController < BaseController
    include MailboxManagement

    before_action :set_mail_domain, only: [:create]
    before_action :set_mail_account, only: [:update, :destroy, :test_delivery, :round_trip_test]

    def create
      @mail_account = @mail_domain.mail_accounts.build(mail_account_params)

      if @mail_account.save
        sync_mailboxes("#{@mail_account.address} を追加しました。")
        redirect_to mail_admin_mail_domains_path
      else
        load_mailbox_index
        render "mail_admin/mail_domains/index", status: :unprocessable_entity
      end
    end

    # Password change only -- the address itself is deliberately not editable,
    # since renaming a mailbox on the server means the old one (and its mail)
    # is archived away. Delete and re-add if the address is wrong.
    def update
      if params.dig(:mail_account, :password).blank?
        redirect_to mail_admin_mail_domains_path, alert: "新しいパスワードを入力してください。"
        return
      end

      if @mail_account.update(password_params)
        sync_mailboxes("#{@mail_account.address} のパスワードを変更しました。")
        redirect_to mail_admin_mail_domains_path
      else
        load_mailbox_index
        render "mail_admin/mail_domains/index", status: :unprocessable_entity
      end
    end

    def destroy
      address = @mail_account.address
      @mail_account.destroy

      sync_mailboxes("#{address} を削除しました。")
      redirect_to mail_admin_mail_domains_path
    end

    # Sends one real mail from this address to an address the admin types in
    # (their own, normally) and records the outcome on the row, so a failure
    # stays visible on the screen after the flash is gone.
    def test_delivery
      to_address = params[:to].to_s.strip

      unless to_address.match?(URI::MailTo::EMAIL_REGEXP)
        redirect_to mail_admin_mail_domains_path, alert: "送信先のメールアドレスを正しく入力してください。"
        return
      end

      deliver_test_mail(to_address)
      redirect_to mail_admin_mail_domains_path
    end

    # Sends a mail from this address to itself and confirms via IMAP that it
    # actually arrived -- a fuller check than #test_delivery, which only
    # proves outbound send didn't raise.
    def round_trip_test
      result = ::MailboxRoundTripTest.new(@mail_account).call

      @mail_account.update_columns(
        last_round_trip_tested_at: Time.current,
        last_round_trip_succeeded: result.succeeded?,
        last_round_trip_error: result.succeeded? ? nil : result.message.truncate(1000)
      )

      flash[result.succeeded? ? :notice : :alert] = "#{@mail_account.address}: #{result.message}"
      redirect_to mail_admin_mail_domains_path
    end

    # Re-applies the current registry to the mail server without changing
    # anything, for retrying after a failed sync (or after the server-side
    # setup was finished).
    def sync
      sync_mailboxes("")
      redirect_to mail_admin_mail_domains_path
    end

    private

    def deliver_test_mail(to_address)
      ::MailboxTestMailer.test_email(
        from_address: @mail_account.address,
        to_address: to_address,
        site_name: @mail_account.mail_domain.name
      ).deliver_now

      record_test_result(to_address, succeeded: true, error: nil)
      flash[:notice] = "#{@mail_account.address} から #{to_address} へテストメールを送信しました。" \
        "受信できない場合は、DNS(SPF)やメールサーバーのログを確認してください。"
    rescue StandardError => e
      # Delivery errors here are expected operational feedback (unreachable
      # relay, rejected sender), not bugs -- surface them instead of 500ing.
      record_test_result(to_address, succeeded: false, error: e.message)
      flash[:alert] = "テストメールの送信に失敗しました: #{e.message.truncate(300)}"
    end

    # update_columns rather than update: a test send doesn't change what the
    # mail server should be serving, so it must not bump updated_at and make
    # the row look 未反映.
    def record_test_result(to_address, succeeded:, error:)
      @mail_account.update_columns(
        last_test_sent_at: Time.current,
        last_test_to: to_address,
        last_test_succeeded: succeeded,
        last_test_error: error&.truncate(1000)
      )
    end

    def set_mail_domain
      @mail_domain = ::MailDomain.find(params[:mail_domain_id])
    end

    def set_mail_account
      @mail_account = ::MailAccount.find(params[:id])
    end

    def mail_account_params
      params.require(:mail_account).permit(:local_part, :password, :password_confirmation)
    end

    def password_params
      params.require(:mail_account).permit(:password, :password_confirmation)
    end
  end
end
