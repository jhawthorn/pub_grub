require "test_helper"

module PubGrub
  class VersionConstraintTest < Minitest::Test
    def setup
      @package = Package.new("pkg") do |p|
        p.add_version "2.0.0"
        p.add_version "1.1.0"
        p.add_version "1.0.0"
      end
    end

    def test_empty_restriction
      constraint = VersionConstraint.new(@package)

      assert_equal 0b111, constraint.bitmap
      assert_equal @package.versions, constraint.versions
      assert_equal "pkg >= 0", constraint.to_s
    end

    def test_semver_restriction
      constraint = VersionConstraint.new(@package, "~> 1.0")

      assert_equal 0b110, constraint.bitmap
      assert_equal @package.versions[1,2], constraint.versions
      assert_equal "pkg ~> 1.0", constraint.to_s
    end

    def test_no_versions
      constraint = VersionConstraint.new(@package, "> 99")

      assert_equal 0b000, constraint.bitmap
      assert_equal [], constraint.versions
      assert_equal "pkg > 99", constraint.to_s
    end
  end
end
