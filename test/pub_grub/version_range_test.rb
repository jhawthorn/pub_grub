require 'pub_grub/version_range'

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
      assert_equal ["> 5"], range.constraints

      refute_includes range, 4
      refute_includes range, 5
      assert_includes range, 6
    end

    def test_only_lower_inclusive
      range = VersionRange.new(min: 5, include_min: true)

      assert_equal ">= 5", range.to_s
      assert_equal [">= 5"], range.constraints

      refute_includes range, 4
      assert_includes range, 5
      assert_includes range, 6
    end


    # Only upper

    def test_only_upper_exclusive
      range = VersionRange.new(max: 7)

      assert_equal "< 7", range.to_s
      assert_equal ["< 7"], range.constraints

      assert_includes range, 6
      refute_includes range, 7
      refute_includes range, 8
    end

    def test_only_upper_inclusive
      range = VersionRange.new(max: 7, include_max: true)

      assert_equal "<= 7", range.to_s
      assert_equal ["<= 7"], range.constraints

      assert_includes range, 6
      assert_includes range, 7
      refute_includes range, 8
    end


    # Both

    def test_both_exclusive
      range = VersionRange.new(min: 5, max: 7)

      assert_equal "> 5, < 7", range.to_s
      assert_equal ["> 5", "< 7"], range.constraints

      refute_includes range, 4
      refute_includes range, 5
      assert_includes range, 6
      refute_includes range, 7
      refute_includes range, 8
    end

    def test_lower_inclusive
      range = VersionRange.new(min: 5, max: 7, include_min: true)

      assert_equal ">= 5, < 7", range.to_s
      assert_equal [">= 5", "< 7"], range.constraints

      refute_includes range, 4
      assert_includes range, 5
      assert_includes range, 6
      refute_includes range, 7
      refute_includes range, 8
    end

    def test_upper_inclusive
      range = VersionRange.new(min: 5, max: 7, include_max: true)

      assert_equal "> 5, <= 7", range.to_s
      assert_equal ["> 5", "<= 7"], range.constraints

      refute_includes range, 4
      refute_includes range, 5
      assert_includes range, 6
      assert_includes range, 7
      refute_includes range, 8
    end

    def test_both_inclusive
      range = VersionRange.new(min: 5, max: 7, include_min: true, include_max: true)

      assert_equal ">= 5, <= 7", range.to_s
      assert_equal [">= 5", "<= 7"], range.constraints

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
      b = VersionRange.new(min: 4, max: 7)

      refute a.intersects?(b)
      refute b.intersects?(a)

      assert_equal a.intersect(b), VersionRange.empty
      assert_equal b.intersect(a), VersionRange.empty
    end

    def test_empty
      empty = VersionRange.empty
      a = VersionRange.new(min: 1, max: 4)

      assert_equal VersionRange.empty, empty

      refute_includes empty, 0
      refute_includes empty, 1
      refute_includes empty, 2
      refute_includes empty, 9999
      refute_includes empty, -9999

      refute empty.intersects?(empty)
      refute a.intersects?(empty)
      refute empty.intersects?(a)

      assert_equal empty, empty.intersect(empty)
      assert_equal empty, a.intersect(empty)
      assert_equal empty, empty.intersect(a)
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
  end
end
