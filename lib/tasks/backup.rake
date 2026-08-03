namespace :backup do
  desc "Back up the database and uploaded files into backups/<timestamp>/, then delete backups older than BACKUP_KEEP_DAYS (default 7) days"
  task create: :environment do
    dest_dir = Backup.create(keep_days: (ENV["BACKUP_KEEP_DAYS"] || 7).to_i)
    puts "Backup created at #{dest_dir}"
  end

  desc "List available backups under backups/"
  task list: :environment do
    backups = Backup.list
    if backups.empty?
      puts "No backups found."
    else
      backups.each { |name| puts name }
    end
  end

  desc "DESTRUCTIVE: restore the database and uploaded files from a backup created by backup:create, overwriting everything currently there. Usage: bin/rails backup:restore BACKUP_DIR=20260803_052300 CONFIRM=yes"
  task restore: :environment do
    dir_name = ENV["BACKUP_DIR"]
    if dir_name.blank?
      abort <<~MSG
        Usage: bin/rails backup:restore BACKUP_DIR=<name> CONFIRM=yes
        Run `bin/rails backup:list` to see available backup names.
      MSG
    end

    backup_dir = Rails.root.join("backups", dir_name)
    unless Dir.exist?(backup_dir)
      abort "Backup not found: #{backup_dir}\nRun `bin/rails backup:list` to see available backup names."
    end

    unless ENV["CONFIRM"] == "yes"
      abort <<~MSG
        This will PERMANENTLY OVERWRITE the current database and every
        uploaded file with the contents of #{backup_dir}.
        If you're sure, re-run with CONFIRM=yes.
      MSG
    end

    puts "Taking a safety backup of the current state before restoring..."
    safety_dir = Backup.create(keep_days: (ENV["BACKUP_KEEP_DAYS"] || 7).to_i)
    puts "Safety backup created at #{safety_dir} (restore from this if something goes wrong)."

    Backup.restore(backup_dir)
    puts "Restored from #{backup_dir}."
  end
end
