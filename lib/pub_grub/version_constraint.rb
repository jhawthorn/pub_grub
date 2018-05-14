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

    def versions
      package.versions.select do |version|
        bitmap[version.id] == 1
      end
    end

    def to_s
      case constraint.length
      when 0
        "#{package.name} >= 0"
      when 1
        "#{package.name} #{constraint[0]}"
      else
        "#{package.name} #{constraint.inspect}"
      end
    end
  end
end
