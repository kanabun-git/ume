require "open3"

# Pushes the mailboxes registered in メールアドレス管理画面(/mailadmin)
# (MailDomain / MailAccount) out to the mail server the site runs on.
#
# Deliberately split in two halves, because the Rails app runs as an
# unprivileged user and must never be handed root:
#
#   1. This class (unprivileged) rewrites two plain export files —
#      domains.txt and accounts.tsv — describing the *desired* state of
#      every domain and mailbox, always in full.
#   2. `script/ume-mailboxctl` (installed as root-owned
#      /usr/local/sbin/ume-mailboxctl, see docs/vps_setup.md) reads those
#      files and regenerates the Postfix/Dovecot maps and maildirs.
#
# The app invokes the helper as `sudo -n /usr/local/sbin/ume-mailboxctl`
# with **no arguments at all** — nothing an admin types on the screen ever
# reaches a privileged command line, so the sudo rule can be pinned to that
# exact argument-less command and there is no injection surface to defend.
#
# Because every sync rewrites the complete state, a deleted MailAccount row
# needs no special handling: it simply stops appearing in the export.
class MailboxProvisioner
  class ExportError < StandardError; end

  # How long the privileged helper is allowed to take (postmap + a couple of
  # systemctl reloads); past this it's treated as a failed sync rather than
  # left to hold the admin's request open.
  COMMAND_TIMEOUT = 60

  DEFAULT_EXPORT_DIR = "/var/lib/ume-mail".freeze
  DOMAINS_FILENAME = "domains.txt".freeze
  ACCOUNTS_FILENAME = "accounts.tsv".freeze

  # status:
  #   :applied  — files written and the mail server picked them up
  #   :exported — files written, but no helper command is configured yet
  #   :skipped  — no export directory on this machine (development/test)
  #   :failed   — something went wrong; message says what
  Result = Struct.new(:status, :message, keyword_init: true) do
    def applied?
      status == :applied
    end

    def failed?
      status == :failed
    end
  end

  def self.export_dir
    ENV["UME_MAIL_EXPORT_DIR"].presence || DEFAULT_EXPORT_DIR
  end

  def self.control_command
    ENV["UME_MAILBOXCTL"].presence
  end

  # True once an operator has created the export directory on this machine,
  # i.e. the mail-server side of the feature has been set up at all.
  def self.configured?
    File.writable?(export_dir)
  end

  def sync!
    unless self.class.configured?
      return Result.new(
        status: :skipped,
        message: "この環境ではメールサーバー連携が未設定のため、登録内容の保存のみ行いました" \
          "(サーバーへの反映は #{self.class.export_dir} を用意すると有効になります)。"
      )
    end

    write_exports

    command = self.class.control_command
    if command.blank?
      return Result.new(
        status: :exported,
        message: "設定ファイルは書き出しましたが、メールサーバーへの反映コマンド(UME_MAILBOXCTL)が" \
          "未設定のため、サーバーには反映されていません。"
      )
    end

    apply(command)
  rescue ExportError => e
    Result.new(status: :failed, message: e.message)
  rescue SystemCallError, IOError => e
    Result.new(status: :failed, message: "設定ファイルの書き出しに失敗しました: #{e.message}")
  end

  private

  def write_exports
    write_atomically(DOMAINS_FILENAME, domains_export)
    write_atomically(ACCOUNTS_FILENAME, accounts_export)
  end

  def domains_export
    MailDomain.pluck(:domain).map { |domain| "#{validated(domain, MailDomain::DOMAIN_FORMAT, domain)}\n" }.join
  end

  def accounts_export
    MailAccount.includes(:mail_domain).map do |account|
      local_part = validated(account.local_part, MailAccount::LOCAL_PART_FORMAT, account.address)
      domain = validated(account.mail_domain.domain, MailDomain::DOMAIN_FORMAT, account.address)
      # Crypt digests are printable ASCII; anything else would break the
      # tab-separated format (or smuggle a line into the Dovecot user file).
      digest = validated(account.password_hash, /\A[!-~]+\z/, account.address)

      "#{local_part}@#{domain}\t#{digest}\t#{domain}/#{local_part}/\n"
    end.join
  end

  # Everything written to the export files is re-checked here even though
  # the models validate the same shapes: these files are the input to a
  # root-privileged script, so a bad row must fail the sync loudly rather
  # than reach it.
  def validated(value, format, address)
    raise ExportError, "「#{address}」の設定に使用できない文字が含まれているため、反映を中止しました。" unless value.to_s.match?(format)

    value.to_s
  end

  def write_atomically(filename, content)
    path = File.join(self.class.export_dir, filename)
    tmp_path = "#{path}.tmp"

    File.open(tmp_path, File::WRONLY | File::CREAT | File::TRUNC, 0o640) do |file|
      file.write(content)
      file.flush
      file.fsync
    end
    File.rename(tmp_path, path)
  end

  def apply(command)
    outcome = run(command)
    return outcome if outcome.is_a?(Result) # timed out

    output, status = outcome
    if status.success?
      # Ordered by default_scope; Postgres rejects UPDATE ... ORDER BY.
      MailAccount.unscope(:order).update_all(synced_at: Time.current)
      Result.new(status: :applied, message: "メールサーバーに反映しました。")
    else
      Result.new(
        status: :failed,
        message: "メールサーバーへの反映に失敗しました: #{output.to_s.strip.truncate(500)}"
      )
    end
  rescue Errno::ENOENT
    Result.new(status: :failed, message: "反映コマンド(#{command})が見つかりませんでした。")
  end

  # Runs the helper with no shell involved and no arguments, draining its
  # output on a separate thread so a chatty script can't fill the pipe and
  # deadlock the wait below.
  def run(command)
    Open3.popen2e("sudo", "-n", command) do |stdin, out, wait_thread|
      stdin.close
      reader = Thread.new { out.read }

      if wait_thread.join(COMMAND_TIMEOUT).nil?
        Process.kill("TERM", wait_thread.pid)
        wait_thread.join(5)
        reader.kill
        return Result.new(
          status: :failed,
          message: "メールサーバーへの反映が#{COMMAND_TIMEOUT}秒以内に終わらなかったため中断しました。"
        )
      end

      [reader.value, wait_thread.value]
    end
  end
end
