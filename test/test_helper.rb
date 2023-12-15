$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'minitest'
require "pub_grub"

PubGrub.logger.level = Logger::DEBUG if ENV['DEBUG']

module PubGrubAssertions
  def assert_solution(source, result, expected)
    expected = Hash[
      expected.map do |package, version|
        [package, Gem::Version.new(version)]
      end
    ]
    expected[PubGrub::Package.root] = 0

    assert_equal expected, result
  end
end

Minitest::Test.include(PubGrubAssertions)
Minitest::Test.make_my_diffs_pretty!

require "minitest/autorun"
