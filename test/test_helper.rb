$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'minitest'
require "pub_grub"

PubGrub.logger.level = Logger::DEBUG if ENV['DEBUG']

module PubGrubAssertions
  def assert_solution(source, result, expected)
    expected =
      expected.map do |package, version|
        source.version(package, version)
      end
    expected -= [PubGrub::Package.root_version]
    result   -= [PubGrub::Package.root_version]

    assert_equal expected.sort, result.sort
  end
end

Minitest::Test.include(PubGrubAssertions)

require "minitest/autorun"
