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
      assert_equal "#<PubGrub::VersionConstraint pkg >= 0 (111)>", constraint.inspect
    end

    def test_semver_restriction
      constraint = VersionConstraint.new(@package, "~> 1.0")

      assert_equal 0b110, constraint.bitmap
      assert_equal @package.versions[1,2], constraint.versions
      assert_equal "pkg ~> 1.0", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg ~> 1.0 (110)>", constraint.inspect
    end

    def test_no_versions
      constraint = VersionConstraint.new(@package, "> 99")

      assert_equal 0b000, constraint.bitmap
      assert_equal [], constraint.versions
      assert_equal "pkg > 99", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg > 99 (000)>", constraint.inspect
    end

    def test_intersection
      a = VersionConstraint.new(@package, "> 1")
      b = VersionConstraint.new(@package, "< 2")

      constraint = a.intersect(b)

      assert_equal 0b010, constraint.bitmap
      assert_equal ["> 1", "< 2"], constraint.constraint
      assert_equal [@package.versions[1]], constraint.versions
      assert_equal "pkg > 1, < 2", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg > 1, < 2 (010)>", constraint.inspect
    end

    def test_no_intersection
      a = VersionConstraint.new(@package, "<= 1")
      b = VersionConstraint.new(@package, ">= 2")

      constraint = a.intersect(b)

      assert_equal 0b000, constraint.bitmap
      assert_equal ["<= 1", ">= 2"], constraint.constraint
      assert_equal [], constraint.versions
      assert_equal "pkg <= 1, >= 2", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg <= 1, >= 2 (000)>", constraint.inspect
    end

    def test_invert_no_restriction
      constraint = VersionConstraint.new(@package).invert
      assert_equal 0b000, constraint.bitmap
      assert_equal ["not >= 0"], constraint.constraint
      assert_equal [], constraint.versions
      assert_equal "pkg not >= 0", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg not >= 0 (000)>", constraint.inspect
    end

    def test_invert_single_constraint
      constraint = VersionConstraint.new(@package, "> 1").invert
      assert_equal 0b100, constraint.bitmap
      assert_equal ["not > 1"], constraint.constraint
      assert_equal "pkg not > 1", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg not > 1 (100)>", constraint.inspect
    end

    def test_invert_multiple_constraints
      constraint = VersionConstraint.new(@package, ["> 1", "< 2"]).invert
      assert_equal 0b101, constraint.bitmap
      assert_equal ["not (> 1, < 2)"], constraint.constraint
      assert_equal "pkg not (> 1, < 2)", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg not (> 1, < 2) (101)>", constraint.inspect
    end

    def test_difference
      a = VersionConstraint.new(@package, [">= 1"])
      b = VersionConstraint.new(@package, ["~> 1"])

      constraint = a.difference(b)

      assert_equal 0b001, constraint.bitmap
      assert_equal [">= 1", "not ~> 1"], constraint.constraint
      assert_equal "pkg >= 1, not ~> 1", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg >= 1, not ~> 1 (001)>", constraint.inspect
    end

    def test_relation
      # foo ~> 1.1.0 is a subset of foo ~> 1.0
      a = VersionConstraint.new(@package, ["~> 1.1.0"])
      b = VersionConstraint.new(@package, ["~> 1.0"])
      assert_equal :subset, a.relation(b)

      # foo ~> 1.0 overlaps with foo > 1.0
      a = VersionConstraint.new(@package, ["> 1.0"])
      b = VersionConstraint.new(@package, ["~> 1.0"])
      assert_equal :overlap, a.relation(b)

      # foo ~> 1.0 is disjoint with foo ~> 2.0
      a = VersionConstraint.new(@package, ["~> 1.0"])
      b = VersionConstraint.new(@package, ["~> 2.0"])
      assert_equal :disjoint, a.relation(b)
    end
  end
end
