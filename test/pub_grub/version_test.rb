require "test_helper"

module PubGrub
  class VersionTest < Minitest::Test
    def test_valid
      assert_match(/\A\d+\.\d+\.\d+(\.[a-zA-Z0-9]+)*\z/, PubGrub::VERSION)
    end
  end
end
