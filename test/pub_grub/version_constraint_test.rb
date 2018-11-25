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
      constraint = VersionConstraint.any(@package)

      assert constraint.any?
      refute constraint.empty?

      assert_equal @package.versions, constraint.versions
      assert_equal "pkg >= 0", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg >= 0>", constraint.inspect
    end

    def test_semver_restriction
      constraint = VersionConstraint.parse(@package, "~> 1.0")

      assert_equal @package.versions[1,2], constraint.versions
      assert_equal "pkg ~> 1.0", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg ~> 1.0>", constraint.inspect
    end

    def test_no_versions
      constraint = VersionConstraint.parse(@package, "> 99")

      assert_equal [], constraint.versions
      assert_equal "pkg > 99", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg > 99>", constraint.inspect
    end

    def test_intersection
      a = VersionConstraint.parse(@package, "> 1")
      b = VersionConstraint.parse(@package, "< 2")

      constraint = a.intersect(b)

      assert_equal ["> 1", "< 2"], constraint.constraint
      assert_equal [@package.versions[1]], constraint.versions
      assert_equal "pkg > 1, < 2", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg > 1, < 2>", constraint.inspect
    end

    def test_no_intersection
      a = VersionConstraint.parse(@package, "<= 1")
      b = VersionConstraint.parse(@package, ">= 2")

      constraint = a.intersect(b)

      assert_equal ["<= 1", ">= 2"], constraint.constraint
      assert_equal [], constraint.versions
      assert_equal "pkg <= 1, >= 2", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg <= 1, >= 2>", constraint.inspect
    end

    def test_invert_no_restriction
      constraint = VersionConstraint.any(@package).invert
      assert_equal ["not >= 0"], constraint.constraint
      assert_equal [], constraint.versions
      assert_equal "pkg not >= 0", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg not >= 0>", constraint.inspect
    end

    def test_invert_single_constraint
      constraint = VersionConstraint.parse(@package, "> 1").invert
      assert_equal ["not > 1"], constraint.constraint
      assert_equal "pkg not > 1", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg not > 1>", constraint.inspect
    end

    def test_invert_multiple_constraints
      constraint = VersionConstraint.parse(@package, ["> 1", "< 2"]).invert
      assert_equal ["not (> 1, < 2)"], constraint.constraint
      assert_equal "pkg not (> 1, < 2)", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg not (> 1, < 2)>", constraint.inspect
    end

    def test_difference
      a = VersionConstraint.parse(@package, [">= 1"])
      b = VersionConstraint.parse(@package, ["~> 1"])

      constraint = a.difference(b)

      assert_equal [">= 1", "not ~> 1"], constraint.constraint
      assert_equal "pkg >= 1, not ~> 1", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg >= 1, not ~> 1>", constraint.inspect
    end

    def test_relation_subset
      # foo ~> 1.1.0 is a subset of foo ~> 1.0
      a = VersionConstraint.parse(@package, ["~> 1.1.0"])
      b = VersionConstraint.parse(@package, ["~> 1.0"])
      assert_equal :subset, a.relation(b)
      assert a.subset?(b)
      assert a.overlap?(b)
      refute a.disjoint?(b)
    end

    def test_relation_overlap
      # foo ~> 1.0 overlaps with foo > 1.0
      a = VersionConstraint.parse(@package, ["> 1.0"])
      b = VersionConstraint.parse(@package, ["~> 1.0"])
      assert_equal :overlap, a.relation(b)
      refute a.subset?(b)
      assert a.overlap?(b)
      refute a.disjoint?(b)
    end

    def test_relation_disjoint
      # foo ~> 1.0 is disjoint with foo ~> 2.0
      a = VersionConstraint.parse(@package, ["~> 1.0"])
      b = VersionConstraint.parse(@package, ["~> 2.0"])
      assert_equal :disjoint, a.relation(b)
      refute a.subset?(b)
      refute a.overlap?(b)
      assert a.disjoint?(b)
    end
  end
end
