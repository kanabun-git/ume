class SiteSetting < ApplicationRecord
  # This table only ever holds a single row: site-wide toggles like
  # maintenance mode don't belong to any particular record, so rather than
  # threading a settings object through every controller, callers just ask
  # for "the" settings via .instance.
  def self.instance
    first_or_create!
  end
end
