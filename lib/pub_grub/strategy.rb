module PubGrub
  class Strategy
    def initialize(source)
      @source = source
    end

    def next_package_and_version(unsatisfied)
      package, range = next_term_to_try_from(unsatisfied)

      version = @source.versions_for(package, range).first

      [package, version]
    end

    private

    def next_term_to_try_from(unsatisfied)
      unsatisfied.min_by do |package, range|
        matching_versions = @source.versions_for(package, range)
        higher_versions = @source.versions_for(package, range.upper_invert)

        [matching_versions.count <= 1 ? 0 : 1, higher_versions.count]
      end
    end
  end
end
