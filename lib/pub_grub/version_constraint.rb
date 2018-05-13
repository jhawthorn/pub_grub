require 'rubygems/requirement'

module PubGrub
  class VersionConstraint
    attr_reader :package, :constraint

    # @param package [PubGrub::Package]
    # @param constraint [String]
    def initialize(package, constraint = nil, bitmap: nil)
      @package = package
      @constraint = constraint || ">= 0"
      @bitmap = nil # Calculated lazily
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

    def versions
      package.versions.select do |version|
        bitmap[version.id] == 1
      end
    end

    def to_s
      "#{package.name} #{constraint}"
    end
  end
end
