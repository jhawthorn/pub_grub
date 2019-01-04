require "test_helper"

module PubGrub
  class VersionTest < Minitest::Test
    def test_valid
      assert_match(/\A\d+\.\d+\.\d+\z/, PubGrub::VERSION)
    end
  end
end
