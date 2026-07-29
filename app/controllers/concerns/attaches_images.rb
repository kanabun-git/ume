module AttachesImages
  extend ActiveSupport::Concern

  private

  # Appends newly-selected files to `record`'s `attachment_name` collection
  # instead of replacing it — the plain has_many_attached setter (assigning
  # via `record.update(photos: [...])`) replaces the whole collection, which
  # would silently drop every existing photo (and, since the per-photo
  # `hidden` moderation flag lives on the attachment row, un-hide anything
  # a platform admin had already moderated).
  #
  # New files are validated up front so a rejected upload never touches
  # storage, then attached and `other_attrs` saved atomically: if saving
  # `other_attrs` fails for an unrelated reason, the newly attached files
  # are rolled back too. Returns true on success; on failure, errors are
  # set on `record` (including `other_attrs` assigned so the form re-renders
  # with the attempted values) and nothing is persisted.
  def update_with_appended_images(record, attachment_name:, new_files:, other_attrs:)
    new_files = Array(new_files).reject(&:blank?)

    image_errors = record.validate_new_images(attachment_name, new_files)
    if image_errors.any?
      image_errors.each { |message| record.errors.add(attachment_name, message) }
      record.assign_attributes(other_attrs)
      return false
    end

    ActiveRecord::Base.transaction do
      record.public_send(attachment_name).attach(new_files) if new_files.any?
      raise ActiveRecord::Rollback unless record.update(other_attrs)
    end

    record.errors.empty?
  end
end
