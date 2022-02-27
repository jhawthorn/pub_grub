require 'test_helper'

module PubGrub
  class VersionUnionTest < Minitest::Test
    def union(ranges)
      VersionUnion.union(ranges)
    end

    def test_any
      assert_equal VersionRange.any, union([VersionRange.any])
      assert_equal VersionRange.any, union([VersionRange.any, VersionRange.any])
      assert_equal VersionRange.any, union([VersionRange.any, VersionRange.empty])
      assert_equal VersionRange.any, union([VersionRange.any, VersionRange.new(min: 2, max: 5)])
    end

    def test_empty
      assert_equal VersionRange.empty, union([VersionRange.empty])
      assert_equal VersionRange.empty, union([VersionRange.empty, VersionRange.empty])
    end

    def test_merge_overlap
      a = union([
        VersionRange.new(min: 2, max: 4),
        VersionRange.new(min: 0, max: 3)
      ])
      assert_equal VersionRange.new(min: 0, max: 4), a
    end

    def test_merge_included_overlap
      a = union([
        VersionRange.new(min: 0, max: 2),
        VersionRange.new(min: 3, max: 5),
        VersionRange.new(min: 3, max: 4, include_min: true)
      ])

      assert_equal "> 0, < 2 OR >= 3, < 5", a.to_s

      refute_includes a, 0
      assert_includes a, 1
      refute_includes a, 2
      assert_includes a, 3
      assert_includes a, 4
      refute_includes a, 5
    end

    def test_merge_contiguous
      a = union([
        VersionRange.new(min: 2, max: 4),
        VersionRange.new(min: 4, max: 6),
        VersionRange.new(min: 4, max: 5, include_min: true)
      ])
      assert_equal VersionRange.new(min: 2, max: 6), a
    end

    def test_eql
      a = union([
        VersionRange.new(min: 1, max: 3),
        VersionRange.new(min: 4, max: 7),
      ])

      assert_operator a, :eql?, a
      refute_operator a.ranges.first, :eql?, a
      refute_operator a, :eql?, a.ranges.first
      assert_operator a, :eql?, union(a.ranges)
    end

    def test_simple
      a = union([
        VersionRange.new(min: 1, max: 3),
        VersionRange.new(min: 4, max: 7),
      ])

      refute a.empty?
      refute a.any?

      assert_equal "> 1, < 3 OR > 4, < 7", a.to_s

      refute_includes a, 0
      refute_includes a, 1
      assert_includes a, 2
      refute_includes a, 3
      refute_includes a, 4
      assert_includes a, 5
      assert_includes a, 6
      refute_includes a, 7
      refute_includes a, 8

      expected = union([
        VersionRange.new(max: 1, include_max: true),
        VersionRange.new(min: 3, max: 4, include_min: true, include_max: true),
        VersionRange.new(min: 7, include_min: true)
      ])
      assert_equal expected, a.invert
    end

    def test_not_equal
      simple = union([
        VersionRange.new(max: 3),
        VersionRange.new(min: 3),
      ])

      assert_includes simple, 2
      refute_includes simple, 3
      assert_includes simple, 4

      assert_equal "!= 3", simple.to_s

      two = union([
        VersionRange.new(max: 3),
        VersionRange.new(min: 3, max: 5),
        VersionRange.new(min: 5),
      ])

      assert_includes two, 2
      refute_includes two, 3
      assert_includes two, 4

      assert_equal "!= 3, != 5", two.to_s

      complex = union([
        VersionRange.new(min: 1, max: 3),
        VersionRange.new(min: 3, max: 5),
        VersionRange.new(min: 5, max: 8),
      ])

      assert_includes complex, 2
      refute_includes complex, 3
      assert_includes complex, 4
      refute_includes complex, 5
      assert_includes complex, 6
      assert_includes complex, 7
      refute_includes complex, 8
      refute_includes complex, 9

      assert_equal "> 1, < 8, != 3, != 5", complex.to_s
    end

    def test_single_overlap
      a = union([
        VersionRange.new(min: 0, max: 1),
        VersionRange.new(min: 2, max: 4),
      ])
      b = union([
        VersionRange.new(min: 3, max: 5),
        VersionRange.new(min: 99, max: 100)
      ])

      assert a.intersects?(b)
      assert b.intersects?(a)

      expected = VersionRange.new(min: 3, max: 4)
      assert_equal expected, a.intersect(b)
      assert_equal expected, b.intersect(a)

      expected = union([
        VersionRange.new(min: 0, max: 1),
        VersionRange.new(min: 2, max: 5),
        VersionRange.new(min: 99, max: 100)
      ])
      assert_equal expected, a.union(b)
      assert_equal expected, b.union(a)
    end

    def test_multiple_overlap
      a = union([
        VersionRange.new(min: 2, max: 5),
        VersionRange.new(min: 6, max: 9),
      ])
      b = union([
        VersionRange.new(min: 4, max: 7),
        VersionRange.new(min: 8, max: 12)
      ])

      assert a.intersects?(b)
      assert b.intersects?(a)

      expected = union([
        VersionRange.new(min: 4, max: 5),
        VersionRange.new(min: 6, max: 7),
        VersionRange.new(min: 8, max: 9),
      ])
      assert_equal expected, a.intersect(b)
      assert_equal expected, b.intersect(a)

      expected = VersionRange.new(min: 2, max: 12)
      assert_equal expected, a.union(b)
      assert_equal expected, b.union(a)
    end

    def test_late_overlap
      a = union([
        VersionRange.new(min: 2, max: 3),
        VersionRange.new(min: 4, max: 5),
        VersionRange.new(min: 6, max: 8)
      ])
      b = union([
        VersionRange.new(min: 0, max: 1),
        VersionRange.new(min: 3, max: 4),
        VersionRange.new(min: 5, max: 6)
      ])

      refute a.intersects?(b)
      refute b.intersects?(a)

      assert_equal VersionRange.empty, a.intersect(b)
      assert_equal VersionRange.empty, b.intersect(a)

      b = b.union(VersionRange.new(min: 7, max: 10))

      expected = VersionRange.new(min: 7, max: 8)
      assert_equal expected, a.intersect(b)
      assert_equal expected, b.intersect(a)
    end

    def test_allows_all?
      a = union([
        VersionRange.new(min: 2, max: 3),
        VersionRange.new(min: 6, max: 7),
      ])
      b = union([
        VersionRange.new(min: 0, max: 4),
        VersionRange.new(min: 6, max: 7),
      ])

      assert b.allows_all?(a)
      refute a.allows_all?(b)
    end
  end
end
