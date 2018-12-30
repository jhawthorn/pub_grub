require "test_helper"

module PubGrub
  class VersionConstraintTest < Minitest::Test
    def setup
      @package = Package.new("pkg")
    end

    def parse(package, constraint)
      PubGrub::RubyGems.parse_constraint(package, constraint)
    end

    def test_empty_restriction
      constraint = VersionConstraint.any(@package)

      assert constraint.any?
      refute constraint.empty?

      assert_equal "pkg >= 0", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg >= 0>", constraint.inspect
    end

    def test_semver_restriction
      constraint = parse(@package, "~> 1.0")

      assert_equal "pkg ~> 1.0", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg ~> 1.0>", constraint.inspect
    end

    def test_no_versions
      constraint = VersionConstraint.empty(@package)

      assert_equal "pkg (no versions)", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg (no versions)>", constraint.inspect
    end

    def test_intersection
      a = parse(@package, "> 1")
      b = parse(@package, "< 2")

      constraint = a.intersect(b)

      assert_equal "pkg > 1, < 2", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg > 1, < 2>", constraint.inspect
    end

    def test_no_intersection
      a = parse(@package, "<= 1")
      b = parse(@package, ">= 2")

      constraint = a.intersect(b)

      assert_equal "pkg (no versions)", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg (no versions)>", constraint.inspect
    end

    def test_invert_no_restriction
      constraint = VersionConstraint.any(@package).invert
      assert_equal "pkg (no versions)", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg (no versions)>", constraint.inspect
    end

    def test_invert_single_constraint
      constraint = parse(@package, "> 1").invert
      assert_equal "pkg <= 1", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg <= 1>", constraint.inspect
    end

    def test_invert_multiple_constraints
      constraint = parse(@package, ["> 1", "< 2"]).invert
      assert_equal "pkg <= 1 OR >= 2", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg <= 1 OR >= 2>", constraint.inspect
    end

    def test_difference
      a = parse(@package, [">= 1"])
      b = parse(@package, ["< 2"])

      constraint = a.difference(b)

      assert_equal "pkg >= 2", constraint.to_s
      assert_equal "#<PubGrub::VersionConstraint pkg >= 2>", constraint.inspect
    end

    def test_relation_subset
      # foo ~> 1.1.0 is a subset of foo ~> 1.0
      a = parse(@package, ["~> 1.1.0"])
      b = parse(@package, ["~> 1.0"])
      assert_equal :subset, a.relation(b)
      assert a.subset?(b)
      assert a.overlap?(b)
      refute a.disjoint?(b)
    end

    def test_relation_overlap
      # foo ~> 1.0 overlaps with foo > 1.0
      a = parse(@package, ["> 1.0"])
      b = parse(@package, ["~> 1.0"])
      assert_equal :overlap, a.relation(b)
      refute a.subset?(b)
      assert a.overlap?(b)
      refute a.disjoint?(b)
    end

    def test_relation_disjoint
      # foo ~> 1.0 is disjoint with foo ~> 2.0
      a = parse(@package, ["~> 1.0"])
      b = parse(@package, ["~> 2.0"])
      assert_equal :disjoint, a.relation(b)
      refute a.subset?(b)
      refute a.overlap?(b)
      assert a.disjoint?(b)
    end
  end
end
