require "csv"
require "fileutils"
require "tmpdir"
require "securerandom"

# Builds an on-demand CSV + attached-files backup archive for a single data
# category (shops, casts, diary entries, videos), downloaded from 運営管理画面
# > データバックアップ. Unlike Backup (lib/backup.rb), which snapshots the
# whole database + storage for disaster recovery, this lets an admin grab
# just one kind of data on demand, without SSH access to the server.
module DataExport
  module_function

  # attachments_for is called with each record and must return an array of
  # already-attached ActiveStorage::Attachment/Attached::One objects (never
  # a not-yet-attached has_one proxy) to save alongside the CSV.
  def build(label, records, attachments_for: ->(_record) { [] })
    Dir.mktmpdir do |work_dir|
      write_csv(File.join(work_dir, "#{label}.csv"), records)

      files_dir = File.join(work_dir, "files")
      FileUtils.mkdir_p(files_dir)
      records.each do |record|
        attachments_for.call(record).each { |attachment| save_attachment(attachment, files_dir, record.id) }
      end

      archive_path = File.join(Dir.tmpdir, "#{label}_#{SecureRandom.hex(8)}.tar.gz")
      begin
        success = system("tar", "-czf", archive_path, "-C", work_dir, ".")
        raise "tar failed while building the #{label} export" unless success

        yield archive_path
      ensure
        FileUtils.rm_f(archive_path)
      end
    end
  end

  def write_csv(path, records)
    CSV.open(path, "w") do |csv|
      next if records.empty?

      csv << records.first.attributes.keys
      records.each { |record| csv << record.attributes.values }
    end
  end

  def save_attachment(attachment, dir, record_id)
    dest_path = File.join(dir, "#{record_id}_#{attachment.filename}")
    File.open(dest_path, "wb") { |file| attachment.download { |chunk| file.write(chunk) } }
  end
end
