module CastPortal
  class DashboardController < BaseController
    def show
      @cast = current_cast_profile
      @recent_diary_entries = @cast&.diary_entries&.limit(5)
      @upcoming_shifts = @cast&.upcoming_shifts&.limit(5)
    end
  end
end
