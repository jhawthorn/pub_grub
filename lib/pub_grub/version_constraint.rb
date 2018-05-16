require 'rubygems/requirement'

module PubGrub
  class VersionConstraint
    attr_reader :package, :constraint

    # @param package [PubGrub::Package]
    # @param constraint [String]
    def initialize(package, constraint = nil, bitmap: nil)
      @package = package
      @constraint = Array(constraint)
      @bitmap = bitmap # Calculated lazily
    end

    def bitmap
      return @bitmap if @bitmap

      # TODO: Should not be hardcoded to rubygems semantics
      requirement = Gem::Requirement.new(constraint)
      @bitmap =
        package.versions.inject(0) do |acc, version|
          if requirement.satisfied_by?(Gem::Version.new(version.name))
            acc | (1 << version.id)
          else
            acc
          end
        end
    end

    def intersect(other)
      unless package == other.package
        raise ArgumentError, "Can only intersect between VersionConstraint of the same package"
      end
      self.class.new(package, constraint + other.constraint, bitmap: bitmap & other.bitmap)
    end

    def invert
      new_bitmap = bitmap ^ ((1 << package.versions.length) - 1)
      new_constraint =
        if constraint.length == 0
          ["not >= 0"]
        elsif constraint.length == 1
          ["not #{constraint[0]}"]
        else
          ["not (#{constraint_string})"]
        end
      self.class.new(package, new_constraint, bitmap: new_bitmap)
    end

    def versions
      package.versions.select do |version|
        bitmap[version.id] == 1
      end
    end

    def to_s
      "#{package.name} #{constraint_string}"
    end

    def constraint_string
      case constraint.length
      when 0
        ">= 0"
      when 1
        "#{constraint[0]}"
      else
        "#{constraint.join(", ")}"
      end
    end

    def inspect
      "#<#{self.class} #{self} (#{bitmap.to_s(2).rjust(package.versions.count, "0")})>"
    end
  end
end
