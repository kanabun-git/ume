require "open3"
require "fileutils"

# Creates a timestamped backup of the database and ActiveStorage files under
# backups/<timestamp>/, invoked via `bin/rails backup:create` (see
# lib/tasks/backup.rake). Old backups are pruned to control disk usage on
# the single small VPS this app runs on.
module Backup
  module_function

  def create(keep_days: 7)
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    dest_dir = Rails.root.join("backups", timestamp)
    FileUtils.mkdir_p(dest_dir)

    dump_database(dest_dir.join("db.sql.gz"))
    archive_storage(dest_dir.join("storage.tar.gz"))
    prune_old_backups(keep_days: keep_days)

    dest_dir
  end

  def dump_database(dest_path)
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    pg_dump_cmd = ["pg_dump", "-U", config[:username].to_s]
    pg_dump_cmd.push("-h", config[:host].to_s) if config[:host].present?
    pg_dump_cmd.push("-p", config[:port].to_s) if config[:port].present?
    pg_dump_cmd.push(config[:database].to_s)

    env = config[:password].present? ? { "PGPASSWORD" => config[:password].to_s } : {}
    statuses = Open3.pipeline([env, *pg_dump_cmd], ["gzip"], out: dest_path.to_s)
    raise "pg_dump failed (exit #{statuses[0].exitstatus})" unless statuses[0].success?
    raise "gzip failed (exit #{statuses[1].exitstatus})" unless statuses[1].success?
  end

  def archive_storage(dest_path)
    storage_dir = Rails.root.join("storage")
    return unless Dir.exist?(storage_dir)

    success = system("tar", "-czf", dest_path.to_s, "-C", Rails.root.to_s, "storage")
    raise "tar failed while archiving storage/" unless success
  end

  def prune_old_backups(keep_days:)
    cutoff = keep_days.days.ago
    Dir.glob(Rails.root.join("backups", "*")).each do |dir|
      next unless File.directory?(dir) && File.mtime(dir) < cutoff

      FileUtils.rm_rf(dir)
      puts "Removed old backup: #{dir}"
    end
  end
end
