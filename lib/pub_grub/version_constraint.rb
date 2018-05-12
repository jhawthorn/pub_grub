module PubGrub
  class VersionConstraint
    attr_reader :package

    def initialize(package, constraint)
      @package = package
    end

    def to_s

    end
  end
end
