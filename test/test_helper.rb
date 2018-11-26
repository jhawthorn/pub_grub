$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'minitest'
require "pub_grub"

PubGrub.logger.level = Logger::DEBUG if ENV['DEBUG']

module PubGrubAssertions
  def assert_solution(source, result, expected)
    expected =
      expected.transform_keys do |package|
        source.package(package)
      end
    expected[PubGrub::Package.root] = "1.0.0"

    assert_equal expected, result
  end
end

Minitest::Test.include(PubGrubAssertions)

require "minitest/autorun"
