require "open3"

# Build version shown in the admin screen footer. Fully derived from git —
# no file to hand-maintain and no risk of forgetting to bump it.
#
# Format: YYYYMMDD.N, where YYYYMMDD is the latest commit's date and N is
# how many commits landed on that date (1-indexed, up to and including the
# latest). Before the site's public launch, the version is prefixed "PR"
# (as requested) — flip RELEASED to true once it goes live.
module BuildVersion
  RELEASED = false

  module_function

  def display
    RELEASED ? version : "PR#{version}"
  end

  def version
    @version ||= "#{commit_date}.#{commits_on(commit_date)}"
  end

  def commit_date
    @commit_date ||= begin
      out, ok = git("log", "-1", "--format=%cd", "--date=format:%Y%m%d")
      ok && out.present? ? out.strip : Time.current.strftime("%Y%m%d")
    end
  end

  def commits_on(date_str)
    out, ok = git("log", "--oneline", "--since=#{date_str} 00:00:00", "--until=#{date_str} 23:59:59")
    ok ? [out.lines.count, 1].max : 1
  end

  def git(*args)
    out, status = Open3.capture2("git", *args, chdir: Rails.root.to_s)
    [out, status.success?]
  rescue StandardError
    ["", false]
  end
end
