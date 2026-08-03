module Admin
  # Lets a platform admin download an on-demand backup of one data category
  # at a time, straight from the browser, without needing SSH access to the
  # server (see also `bin/rails backup:create` for the full automated
  # database + storage backup).
  class DataBackupsController < BaseController
    def index
    end

    def shops
      send_export("shops", ::Shop.order(:id), attachments_for: ->(shop) { shop.photos.attached? ? shop.photos.to_a : [] })
    end

    def casts
      send_export("casts", ::Cast.order(:id), attachments_for: ->(cast) { cast.photos.attached? ? cast.photos.to_a : [] })
    end

    def diary_entries
      send_export("diary_entries", ::DiaryEntry.order(:id), attachments_for: lambda { |entry|
        attachments = entry.images.attached? ? entry.images.to_a : []
        attachments << entry.video if entry.video.attached?
        attachments
      })
    end

    def videos
      send_export("videos", ::ShopPageBlock.movie.order(:id), attachments_for: ->(block) { block.video_file.attached? ? [block.video_file] : [] })
    end

    private

    def send_export(label, records, attachments_for:)
      ::DataExport.build(label, records, attachments_for: attachments_for) do |archive_path|
        send_data File.binread(archive_path),
                  filename: "#{label}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.tar.gz",
                  type: "application/gzip"
      end
    end
  end
end
