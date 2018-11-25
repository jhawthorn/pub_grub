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

    def intersects?(other)
      ranges.any? { |r| r.intersects?(other) }
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
  end
end
