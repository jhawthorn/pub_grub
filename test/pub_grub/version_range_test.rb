require 'test_helper'

module PubGrub
  class VersionRangeTest < Minitest::Test
    def test_no_restriction
      range = VersionRange.any

      assert_equal "any", range.to_s
    end


    # Only lower

    def test_only_lower_exclusive
      range = VersionRange.new(min: 5)

      assert_equal "> 5", range.to_s

      refute_includes range, 4
      refute_includes range, 5
      assert_includes range, 6
    end

    def test_only_lower_inclusive
      range = VersionRange.new(min: 5, include_min: true)

      assert_equal ">= 5", range.to_s

      refute_includes range, 4
      assert_includes range, 5
      assert_includes range, 6
    end

    def only_lower_ill_defined
      assert_raise(ArgumentError) { VersionRange.new(min: 5, include_max: true) }
    end

    # Only upper

    def test_only_upper_exclusive
      range = VersionRange.new(max: 7)

      assert_equal "< 7", range.to_s

      assert_includes range, 6
      refute_includes range, 7
      refute_includes range, 8
    end

    def test_only_upper_inclusive
      range = VersionRange.new(max: 7, include_max: true)

      assert_equal "<= 7", range.to_s

      assert_includes range, 6
      assert_includes range, 7
      refute_includes range, 8
    end

    def only_upper_ill_defined
      assert_raise(ArgumentError) { VersionRange.new(max: 7, include_min: true) }
    end

    # Both

    def test_both_exclusive
      range = VersionRange.new(min: 5, max: 7)

      assert_equal "> 5, < 7", range.to_s

      refute_includes range, 4
      refute_includes range, 5
      assert_includes range, 6
      refute_includes range, 7
      refute_includes range, 8
    end

    def test_lower_inclusive
      range = VersionRange.new(min: 5, max: 7, include_min: true)

      assert_equal ">= 5, < 7", range.to_s

      refute_includes range, 4
      assert_includes range, 5
      assert_includes range, 6
      refute_includes range, 7
      refute_includes range, 8
    end

    def test_upper_inclusive
      range = VersionRange.new(min: 5, max: 7, include_max: true)

      assert_equal "> 5, <= 7", range.to_s

      refute_includes range, 4
      refute_includes range, 5
      assert_includes range, 6
      assert_includes range, 7
      refute_includes range, 8
    end

    def test_both_inclusive
      range = VersionRange.new(min: 5, max: 7, include_min: true, include_max: true)

      assert_equal ">= 5, <= 7", range.to_s

      refute_includes range, 4
      assert_includes range, 5
      assert_includes range, 6
      assert_includes range, 7
      refute_includes range, 8
    end

    def test_intersection
      a = VersionRange.new(min: 1, max: 5)
      b = VersionRange.new(min: 4, max: 7)

      assert a.intersects?(a)
      assert b.intersects?(b)

      assert a.intersects?(b)
      assert b.intersects?(a)

      assert_equal a, a.intersect(a)
      assert_equal b, b.intersect(b)

      assert_equal a.intersect(b), VersionRange.new(min: 4, max: 5)
    end

    def test_intersection_includes
      a = VersionRange.new(min: 1, max: 5, include_max: true)
      b = VersionRange.new(min: 4, max: 7, include_min: true)

      assert a.intersects?(a)
      assert b.intersects?(b)

      assert a.intersects?(b)
      assert b.intersects?(a)

      assert_equal a, a.intersect(a)
      assert_equal b, b.intersect(b)

      assert_equal a.intersect(b), VersionRange.new(min: 4, max: 5, include_min: true, include_max: true)
    end

    def test_intersection_unbound
      a = VersionRange.new(min: 4)
      b = VersionRange.new(max: 7)

      assert a.intersects?(a)
      assert b.intersects?(b)

      assert a.intersects?(b)
      assert b.intersects?(a)

      assert_equal a, a.intersect(a)
      assert_equal b, b.intersect(b)

      assert_equal VersionRange.new(min: 4, max: 7), a.intersect(b)
      assert_equal VersionRange.new(min: 4, max: 7), a.intersect(b)
    end

    def test_no_intersection
      a = VersionRange.new(min: 1, max: 4)
      b = VersionRange.new(min: 5, max: 7)

      refute a.intersects?(b)
      refute b.intersects?(a)

      assert_equal a.intersect(b), VersionRange.empty
      assert_equal b.intersect(a), VersionRange.empty
    end

    def test_touching_no_intersection
      a = VersionRange.new(min: 1, max: 4)
      b = VersionRange.new(min: 4, max: 7)

      refute a.intersects?(b)
      refute b.intersects?(a)

      assert_equal a.intersect(b), VersionRange.empty
      assert_equal b.intersect(a), VersionRange.empty
    end

    def test_empty
      empty = VersionRange.empty
      a = VersionRange.new(min: 1, max: 4)

      assert_same VersionRange.empty, empty

      refute_includes empty, 0
      refute_includes empty, 1
      refute_includes empty, 2
      refute_includes empty, 9999
      refute_includes empty, -9999

      refute_operator empty, :intersects?, empty
      refute_operator a, :intersects?, empty
      refute_operator empty, :intersects?, a

      assert_equal empty, empty.intersect(empty)
      assert_equal empty, a.intersect(empty)
      assert_equal empty, empty.intersect(a)

      assert_equal VersionRange.any, empty.invert
      assert_equal empty, VersionRange.any.invert

      assert empty.hash

      assert_operator empty, :eql?, empty
      refute_operator a, :eql?, empty
      refute_operator empty, :eql?, a
    end

    def test_contiguous_to
      # intersecting
      assert (VersionRange.any).contiguous_to?(VersionRange.any)
      assert (VersionRange.new(min: 1, max: 4)).contiguous_to?(VersionRange.new(min: 3, max: 6))

      # touching
      refute (VersionRange.new(min: 1, max: 3)).contiguous_to?(
        VersionRange.new(min: 3, max: 6))
      assert (VersionRange.new(min: 1, max: 3, include_max: true)).contiguous_to?(
        VersionRange.new(min: 3, max: 6))
      assert (VersionRange.new(min: 1, max: 3)).contiguous_to?(
        VersionRange.new(min: 3, max: 6, include_min: true))
      refute (VersionRange.new(min: 1, max: 3, include_min: true)).contiguous_to?(
        VersionRange.new(min: 3, max: 6, include_max: true))

      refute VersionRange.new.contiguous_to?(VersionRange.empty)
      assert VersionRange.new.contiguous_to?(VersionRange.new)
      refute VersionRange.empty.contiguous_to?(VersionRange.empty)
    end

    def test_allows_all
      assert (VersionRange.any).allows_all?(VersionRange.empty)
      assert (VersionRange.any).allows_all?(VersionRange.any)
      assert (VersionRange.empty).allows_all?(VersionRange.empty)
      refute (VersionRange.empty).allows_all?(VersionRange.any)

      assert (VersionRange.new(min: 1, max: 4)).allows_all?(
        VersionRange.new(min: 2, max: 3))
      assert (VersionRange.new(min: 2, max: 3)).allows_all?(
        VersionRange.new(min: 2, max: 3))
      refute (VersionRange.new(min: 1, max: 3)).allows_all?(
        VersionRange.new(min: 2, max: 4))
      refute (VersionRange.new(min: 2, max: 3)).allows_all?(
        VersionRange.new(min: 2, max: 3, include_min: true))
      refute (VersionRange.new(min: 2, max: 3)).allows_all?(
        VersionRange.new(min: 2, max: 3, include_max: true))
      assert (VersionRange.new(min: 1, max: 4)).allows_all?(
        VersionRange.new(min: 2, max: 3, include_min: true, include_max: true))
    end

    def test_select_versions
      versions = (0..9).to_a

      range = VersionRange.empty
      expected = []
      assert_equal expected, versions.select { |v| range.include?(v) }
      assert_equal expected, range.select_versions(versions)

      range = VersionRange.any
      expected = versions
      assert_equal expected, versions.select { |v| range.include?(v) }
      assert_equal expected, range.select_versions(versions)

      range = VersionRange.new(min: 2, max: 5)
      expected = [3, 4]
      assert_equal expected, versions.select { |v| range.include?(v) }
      assert_equal expected, range.select_versions(versions)

      range = VersionRange.new(min: 2, max: 5, include_min: true)
      expected = [2, 3, 4]
      assert_equal expected, versions.select { |v| range.include?(v) }
      assert_equal expected, range.select_versions(versions)

      range = VersionRange.new(min: 2, max: 5, include_max: true)
      expected = [3, 4, 5]
      assert_equal expected, versions.select { |v| range.include?(v) }
      assert_equal expected, range.select_versions(versions)

      range = VersionRange.new(min: 2, max: 5, include_min: true, include_max: true)
      expected = [2, 3, 4, 5]
      assert_equal expected, versions.select { |v| range.include?(v) }
      assert_equal expected, range.select_versions(versions)

      range = VersionRange.new(min: nil, max: 5)
      expected = [0, 1, 2, 3, 4]
      assert_equal expected, versions.select { |v| range.include?(v) }
      assert_equal expected, range.select_versions(versions)

      range = VersionRange.new(min: 2, max: nil)
      expected = [3, 4, 5, 6, 7, 8, 9]
      assert_equal expected, versions.select { |v| range.include?(v) }
      assert_equal expected, range.select_versions(versions)
    end

    def test_select_versions_outside_range
      versions = (3..5).to_a

      range = VersionRange.new(min: 5)
      assert_equal [], range.select_versions(versions)

      range = VersionRange.new(max: 2)
      assert_equal [], range.select_versions(versions)
    end

    def test_select_versions_from_empty_list
      versions = []

      range = VersionRange.empty
      assert_equal [], range.select_versions(versions)

      range = VersionRange.any
      assert_equal [], range.select_versions(versions)

      range = VersionRange.new(min: 2, max: 5)
      assert_equal [], range.select_versions(versions)

      range = VersionRange.new(min: 2, max: 5, include_min: true)
      assert_equal [], range.select_versions(versions)

      range = VersionRange.new(min: 2, max: 5, include_max: true)
      assert_equal [], range.select_versions(versions)

      range = VersionRange.new(min: 2, max: 5, include_min: true, include_max: true)
      assert_equal [], range.select_versions(versions)

      range = VersionRange.new(min: nil, max: 5)
      assert_equal [], range.select_versions(versions)

      range = VersionRange.new(min: 2, max: nil)
      assert_equal [], range.select_versions(versions)
    end

    def test_equality
      a = VersionRange.new(min: 2, max: nil)
      b = VersionRange.new(min: 2, max: nil)
      assert_equal a, a
      assert_equal a, b
      assert_equal b, a
      assert_equal b, b

      a = VersionRange.new(min: 2, max: nil)
      b = VersionRange.new(min: 2, max: nil, include_min: true)
      assert_equal a, a
      refute_equal a, b
      refute_equal b, a
      assert_equal b, b
    end

    def test_named_version_range_equality
      a = VersionRange.new(min: 2, max: nil)
      b = VersionRange.new(name: "more than two", min: 2, max: nil)
      assert_equal "more than two", b.to_s
      assert_equal a, a
      assert_equal a, b
      assert_equal b, a
      assert_equal b, b
    end

    def test_to_s_with_custom_versions
      version = Class.new do
        attr_reader :version, :platform

        def initialize(version, platform = "ruby")
          @version = version
          @platform = platform
        end

        def ==(other)
          @version == other.version && @platform == other.platform
        end

        def to_s
          version.to_s
        end
      end

      a = VersionRange.new(min: version.new(2), max: version.new(2, "linux"))
      assert_equal "= 2", a.to_s
    end

    def test_contiguous_intersect
      a = VersionRange.new(min: nil, max: 2)
      b = VersionRange.new(min: 2, max: nil)
      refute a.intersects?(b)
      refute b.intersects?(a)
      assert_equal VersionRange.empty, a.intersect(b)
      assert_equal VersionRange.empty, a.intersect(b)

      a = VersionRange.new(min: nil, max: 2, include_max: true)
      b = VersionRange.new(min: 2, max: nil)
      refute a.intersects?(b)
      refute b.intersects?(a)
      assert_equal VersionRange.empty, a.intersect(b)
      assert_equal VersionRange.empty, a.intersect(b)

      a = VersionRange.new(min: nil, max: 2, include_max: true)
      b = VersionRange.new(min: 2, max: nil, include_min: true)
      c = VersionRange.new(min: 2, max: 2, include_min: true, include_max: true)
      assert a.intersects?(b)
      assert b.intersects?(a)
      assert_equal c, a.intersect(b)
      assert_equal c, a.intersect(b)
    end
  end
end
