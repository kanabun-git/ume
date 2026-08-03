namespace :backup do
  desc "Back up the database and uploaded files into backups/<timestamp>/, then delete backups older than BACKUP_KEEP_DAYS (default 7) days"
  task create: :environment do
    dest_dir = Backup.create(keep_days: (ENV["BACKUP_KEEP_DAYS"] || 7).to_i)
    puts "Backup created at #{dest_dir}"
  end
end
