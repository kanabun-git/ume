require "test_helper"
require "backup"
require "zlib"

class BackupTest < ActiveSupport::TestCase
  test "create produces a database dump and storage archive, and prunes backups older than keep_days" do
    stale_dir = Rails.root.join("backups", "stale_test_backup")
    FileUtils.mkdir_p(stale_dir)
    FileUtils.touch(stale_dir, mtime: 10.days.ago.to_time)

    dest_dir = Backup.create(keep_days: 7)

    begin
      assert File.exist?(dest_dir.join("db.sql.gz"))
      assert File.exist?(dest_dir.join("storage.tar.gz"))
      assert_not File.exist?(stale_dir), "backups older than keep_days should be pruned"

      dump_contents = Zlib::GzipReader.open(dest_dir.join("db.sql.gz"), &:read)
      assert_includes dump_contents, "PostgreSQL database dump"
    ensure
      FileUtils.rm_rf(dest_dir)
      FileUtils.rm_rf(stale_dir)
    end
  end
end
