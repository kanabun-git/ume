# Shared by the two メールアドレス管理 controllers (domains and the addresses
# under them), which both render the same single management screen and both
# have to push their changes out to the mail server.
module MailboxManagement
  extend ActiveSupport::Concern

  private

  # Every form on the screen posts to one of the two controllers and, on
  # failure, re-renders this same screen with the invalid record in place,
  # so both need the full set of ivars it reads.
  def load_mailbox_index
    @mail_domains = ::MailDomain.includes(:mail_accounts)
    @mail_domain ||= ::MailDomain.new
    @mail_account ||= ::MailAccount.new
    @provisioner_configured = ::MailboxProvisioner.configured?
    @provisioner_command = ::MailboxProvisioner.control_command
  end

  # `notice` describes the DB change that already succeeded; the sync
  # outcome (applied / not configured / failed) is appended to it, or
  # raised separately as an alert when the server rejected the change.
  def sync_mailboxes(notice)
    result = ::MailboxProvisioner.new.sync!

    flash[:alert] = result.message if result.failed?
    flash[:notice] = result.failed? ? notice : "#{notice}#{result.message}"
  end
end
