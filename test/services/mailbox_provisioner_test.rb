require "test_helper"

class MailboxProvisionerTest < ActiveSupport::TestCase
  setup do
    @export_dir = Dir.mktmpdir("ume-mail-test")
    @mail_domain = MailDomain.create!(name: "サイト本体", domain: "example.com")
  end

  teardown do
    FileUtils.remove_entry(@export_dir)
  end

  test "does nothing but say so when no export directory exists on this machine" do
    result = with_env("UME_MAIL_EXPORT_DIR" => File.join(@export_dir, "missing")) do
      MailboxProvisioner.new.sync!
    end

    assert_equal :skipped, result.status
    assert_match "未設定", result.message
  end

  test "writes every domain and address out, but reports that nothing was applied without a command" do
    @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")
    MailDomain.create!(name: "キャストポータル", domain: "staff.example.net")

    result = with_env("UME_MAIL_EXPORT_DIR" => @export_dir) { MailboxProvisioner.new.sync! }

    assert_equal :exported, result.status
    assert_equal "example.com\nstaff.example.net\n", File.read(File.join(@export_dir, "domains.txt"))

    address, digest, maildir = File.read(File.join(@export_dir, "accounts.tsv")).chomp.split("\t")
    assert_equal "info@example.com", address
    assert digest.start_with?("$6$")
    assert_equal "example.com/info/", maildir
  end

  test "a deleted address simply stops appearing in the export" do
    account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")
    @mail_domain.mail_accounts.create!(local_part: "support", password: "password1234")

    with_env("UME_MAIL_EXPORT_DIR" => @export_dir) do
      MailboxProvisioner.new.sync!
      account.destroy
      MailboxProvisioner.new.sync!
    end

    exported = File.read(File.join(@export_dir, "accounts.tsv"))
    assert_match "support@example.com", exported
    assert_no_match(/info@example\.com/, exported)
  end

  test "the export file is not readable by other users" do
    @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

    with_env("UME_MAIL_EXPORT_DIR" => @export_dir) { MailboxProvisioner.new.sync! }

    mode = File.stat(File.join(@export_dir, "accounts.tsv")).mode & 0o777
    assert_equal 0, mode & 0o007, "password digests must not be world-readable"
  end

  test "marks every address as synced when the mail server accepted the change" do
    account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")
    assert_not account.synced?

    result = run_with_stub_command("#!/bin/sh\nexit 0\n")

    assert_equal :applied, result.status
    assert account.reload.synced?
  end

  test "reports the command's own output when the mail server rejected the change" do
    account = @mail_domain.mail_accounts.create!(local_part: "info", password: "password1234")

    result = run_with_stub_command("#!/bin/sh\necho 'postmap: バッドな設定です' >&2\nexit 1\n")

    assert result.failed?
    assert_match "postmap", result.message
    assert_not account.reload.synced?, "a failed sync must leave the row marked 未反映"
  end

  test "reports a missing helper command instead of raising" do
    result = with_env(
      "UME_MAIL_EXPORT_DIR" => @export_dir,
      "UME_MAILBOXCTL" => File.join(@export_dir, "does-not-exist")
    ) { MailboxProvisioner.new.sync! }

    assert result.failed?
  end

  private

  # The provisioner shells out via `sudo -n <command>`; the stub stands in
  # for both, so the test never needs real privileges.
  def run_with_stub_command(script)
    bin_dir = File.join(@export_dir, "bin")
    FileUtils.mkdir_p(bin_dir)
    sudo = File.join(bin_dir, "sudo")
    # Swallow sudo's own -n flag and run whatever comes after it.
    File.write(sudo, "#!/bin/sh\nshift\nexec \"$@\"\n")
    command = File.join(bin_dir, "mailboxctl")
    File.write(command, script)
    FileUtils.chmod(0o755, [sudo, command])

    with_env(
      "UME_MAIL_EXPORT_DIR" => @export_dir,
      "UME_MAILBOXCTL" => command,
      "PATH" => "#{bin_dir}:#{ENV["PATH"]}"
    ) { MailboxProvisioner.new.sync! }
  end

  def with_env(values)
    original = values.keys.index_with { |key| ENV[key] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    original.each { |key, value| ENV[key] = value }
  end
end
