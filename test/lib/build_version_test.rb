require "test_helper"
require "build_version"

class BuildVersionTest < ActiveSupport::TestCase
  test "version matches YYYYMMDD.N" do
    assert_match(/\A\d{8}\.\d+\z/, BuildVersion.version)
  end

  test "display is prefixed with PR while RELEASED is false" do
    assert_equal false, BuildVersion::RELEASED
    assert_equal "PR#{BuildVersion.version}", BuildVersion.display
  end
end
