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
      assert_includes dump_contents, "DROP TABLE IF EXISTS", "dumps must be self-contained restores (see restore_database)"
    ensure
      FileUtils.rm_rf(dest_dir)
      FileUtils.rm_rf(stale_dir)
    end
  end
end

# restore shells out to psql against the real database connection, so the
# data it's restoring has to actually be committed -- not sitting inside a
# test's own uncommitted transaction, invisible to that separate connection.
# Hence disabling transactional tests here and cleaning up by hand.
class BackupRestoreTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  test "restore rolls the database back to what a previous backup captured" do
    shop = create_shop(catch_copy: "ORIGINAL_MARKER")
    backup_dir = Backup.create(keep_days: 30)

    begin
      shop.update!(catch_copy: "CORRUPTED_AFTER_BACKUP")

      Backup.restore(backup_dir)

      assert_equal "ORIGINAL_MARKER", Shop.find(shop.id).catch_copy
    ensure
      FileUtils.rm_rf(backup_dir)
      shop.destroy # cascades to its shop_page_blocks/cast_page_blocks
      shop.area.destroy
      shop.genre.destroy
      shop.plan.destroy
    end
  end
end
