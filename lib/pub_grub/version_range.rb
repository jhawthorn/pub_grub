# frozen_string_literal: true

module PubGrub
  class VersionRange
    attr_reader :min, :max, :include_min, :include_max

    def initialize(min: nil, max: nil, include_min: false, include_max: false)
      @min = min
      @max = max
      @include_min = include_min
      @include_max = include_max

      if min && max
        if min > max
          raise ArgumentError, "min version #{min} must be less than max #{max}"
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

    def to_s
      constraints.join(", ")
    end
  end
end
