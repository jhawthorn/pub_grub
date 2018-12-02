# frozen_string_literal: true

module PubGrub
  class VersionUnion
    attr_reader :ranges

    def self.normalize_ranges(ranges)
      ranges = ranges.flat_map do |range|
        if range.is_a?(VersionUnion)
          range.ranges
        else
          [range]
        end
      end

      ranges.reject!(&:empty?)

      return [] if ranges.empty?

      mins, ranges = ranges.partition { |r| !r.min }
      original_ranges = mins + ranges.sort_by { |r| [r.include_min ? 0 : 1, r.min] }
      ranges = [original_ranges.shift]
      original_ranges.each do |range|
        if ranges.last.contiguous_to?(range)
          ranges << ranges.pop.span(range)
        else
          ranges << range
        end
      end

      ranges
    end

    def self.union(ranges)
      ranges = normalize_ranges(ranges)

      if ranges.size == 0
        VersionRange.empty
      elsif ranges.size == 1
        ranges[0]
      else
        new(ranges)
      end
    end

    def initialize(ranges)
      raise ArgumentError unless ranges.all? { |r| r.instance_of?(VersionRange) }
      @ranges = ranges
    end

    def include?(version)
      !!ranges.bsearch {|r| r.compare_version(version) }
    end

    def select_versions(versions)
      ranges.flat_map do |range|
        range.select_versions(versions)
      end
    end

    def intersects?(other)
      my_ranges = ranges.dup
      other_ranges =
        if other.instance_of?(VersionRange)
          [other]
        else
          other.ranges.dup
        end

      my_range = my_ranges.shift
      other_range = other_ranges.shift
      while my_range && other_range
        if my_range.intersects?(other_range)
          return true
        end

        if !my_range.max || (other_range.max && other_range.max < my_range.max)
          other_range = other_ranges.shift
        else
          my_range = my_ranges.shift
        end
      end
    end
    alias_method :allows_any?, :intersects?

    def allows_all?(other)
      other_ranges =
        if other.is_a?(VersionUnion)
          other.ranges
        else
          [other]
        end

      other_ranges.all? do |other_range|
        ranges.any? do |range|
          range.allows_all?(other_range)
        end
      end
    end

    def empty?
      false
    end

    def any?
      false
    end

    def intersect(other)
      new_ranges = ranges.map{ |r| r.intersect(other) }
      VersionUnion.union(new_ranges)
    end

    def invert
      ranges.map(&:invert).inject(:intersect)
    end

    def union(other)
      VersionUnion.union([self, other])
    end

    def to_s
      ranges.map(&:to_s).join(" OR ")
    end

    def inspect
      "#<#{self.class} #{to_s}>"
    end

    def ==(other)
      self.class == other.class &&
        self.ranges == other.ranges
    end
  end
end
