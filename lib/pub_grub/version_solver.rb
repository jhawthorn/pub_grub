require 'pub_grub/partial_solution'

module PubGrub
  class VersionSolver
    def initialize(source:)
      @source = source
    end

    def logger
      PubGrub.logger
    end
  end
end
