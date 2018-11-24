# frozen_string_literal: true

module PubGrub
  class VersionRange
    attr_reader :min, :max, :include_min, :include_max

    class Empty < VersionRange
      undef_method :min, :max, :include_min, :include_max

      def initialize
      end

      def empty?
        true
      end

      def intersects?(_)
        false
      end

      def include?(_)
        false
      end

      def any?
        false
      end

      def constraints
        ["(no versions)"]
      end

      def ==(other)
        other.class == self.class
      end
    end

    def self.empty
      Empty.new
    end

    def initialize(min: nil, max: nil, include_min: false, include_max: false)
      @min = min
      @max = max
      @include_min = include_min
      @include_max = include_max

      if min && max
        if min > max
          raise ArgumentError, "min version #{min} must be less than max #{max}"
        elsif min == max && (!include_min || !include_max)
          raise ArgumentError, "include_min and include_max must be true when min == max"
        end
      end
    end

    def include?(version)
      if min
        return false if version < min
        return false if !include_min && version == min
      end

      if max
        return false if version > max
        return false if !include_max && version == max
      end

      true
    end

    def strictly_lower?(other)
      return false if !max || !other.min

      case max <=> other.min
      when 0
        !include_max || !other.include_min
      when -1
        true
      when 1
        false
      end
    end

    def strictly_higher?(other)
      other.strictly_lower?(self)
    end

    def intersects?(other)
      return false if other.empty?
      !strictly_lower?(other) && !strictly_higher?(other)
    end

    def intersect(other)
      if intersects?(other)
        self
      else
        self.class.empty
      end
    end

    def constraints
      return ["any"] if any?

      c = []
      c << "#{include_min ? ">=" : ">"} #{min}" if min
      c << "#{include_max ? "<=" : "<"} #{max}" if max
      c
    end

    def any?
      !min && !max
    end

    def empty?
      false
    end

    def to_s
      constraints.join(", ")
    end

    def inspect
      "#<#{self.class} #{to_s}>"
    end

    def ==(other)
      self.class == other.class &&
        min == other.min &&
        max == other.max &&
        include_min == other.include_min &&
        include_max
    end
  end
end
