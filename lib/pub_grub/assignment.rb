module PubGrub
  class Assignment
    attr_reader :term, :cause, :level
    def initialize(term, cause, level)
      @term = term
      @cause = cause
      @level = level
    end

    def self.decision(version, level)
      term = Term.new(VersionConstraint.exact(version), true)
      new(term, :decision, level)
    end
  end
end
