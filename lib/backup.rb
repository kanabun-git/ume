require "open3"
require "fileutils"

# Creates and restores a timestamped backup of the database and ActiveStorage
# files under backups/<timestamp>/, invoked via `bin/rails backup:create` /
# `bin/rails backup:restore` (see lib/tasks/backup.rake). Old backups are
# pruned to control disk usage on the single small VPS this app runs on.
#
# Restoring is deliberately CLI-only (no admin-screen button): it overwrites
# the live database and every uploaded file, so it needs the deliberate
# friction of SSH access plus an explicit CONFIRM=yes, not a single misclick.
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

  # Overwrites the current database and storage/ with the contents of a
  # backup directory previously created by .create. Callers are expected to
  # have already taken their own "just in case" safety backup first (the
  # backup:restore rake task does this automatically).
  def restore(dir)
    dir = Pathname.new(dir.to_s)
    raise "Backup directory not found: #{dir}" unless Dir.exist?(dir)

    db_dump = dir.join("db.sql.gz")
    restore_database(db_dump) if File.exist?(db_dump)

    storage_archive = dir.join("storage.tar.gz")
    restore_storage(storage_archive) if File.exist?(storage_archive)

    dir
  end

  def dump_database(dest_path)
    # --clean --if-exists makes the dump drop-and-recreate every object it
    # contains, so restoring it against a database that already has tables
    # (the normal case) works without a separate "wipe the schema" step.
    pg_dump_cmd = ["pg_dump", "--clean", "--if-exists", *pg_connection_args]

    statuses = Open3.pipeline([pg_env, *pg_dump_cmd], ["gzip"], out: dest_path.to_s)
    raise "pg_dump failed (exit #{statuses[0].exitstatus})" unless statuses[0].success?
    raise "gzip failed (exit #{statuses[1].exitstatus})" unless statuses[1].success?
  end

  def restore_database(gz_path)
    psql_cmd = ["psql", "-v", "ON_ERROR_STOP=1", "-q", *pg_connection_args]

    # -q plus discarding stdout: psql still prints each statement's result
    # (e.g. "setval" from sequence resets) without this, which is just noise
    # for the person running this from the command line.
    statuses = Open3.pipeline(["gunzip", "-c", gz_path.to_s], [pg_env, *psql_cmd], out: File::NULL)
    raise "gunzip failed (exit #{statuses[0].exitstatus})" unless statuses[0].success?
    raise "psql restore failed (exit #{statuses[1].exitstatus})" unless statuses[1].success?
  end

  def archive_storage(dest_path)
    storage_dir = Rails.root.join("storage")
    return unless Dir.exist?(storage_dir)

    success = system("tar", "-czf", dest_path.to_s, "-C", Rails.root.to_s, "storage")
    raise "tar failed while archiving storage/" unless success
  end

  def restore_storage(tar_path)
    storage_dir = Rails.root.join("storage")
    FileUtils.rm_rf(storage_dir)

    success = system("tar", "-xzf", tar_path.to_s, "-C", Rails.root.to_s)
    raise "tar failed while restoring storage/" unless success
  end

  def prune_old_backups(keep_days:)
    cutoff = keep_days.days.ago
    Dir.glob(Rails.root.join("backups", "*")).each do |dir|
      next unless File.directory?(dir) && File.mtime(dir) < cutoff

      FileUtils.rm_rf(dir)
      puts "Removed old backup: #{dir}"
    end
  end

  def list
    Dir.glob(Rails.root.join("backups", "*")).select { |dir| File.directory?(dir) }.sort.map { |dir| File.basename(dir) }
  end

  def pg_connection_args
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    args = ["-U", config[:username].to_s]
    args.push("-h", config[:host].to_s) if config[:host].present?
    args.push("-p", config[:port].to_s) if config[:port].present?
    args.push(config[:database].to_s)
    args
  end

  def pg_env
    password = ActiveRecord::Base.connection_db_config.configuration_hash[:password]
    password.present? ? { "PGPASSWORD" => password.to_s } : {}
  end
end
