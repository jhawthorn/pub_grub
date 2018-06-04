module PubGrub
  class Assignment
    attr_reader :term, :cause, :decision_level
    def initialize(term, cause, decision_level)
      @term = term
      @cause = cause
      @decision_level = decision_level
    end

    def self.decision(version, decision_level)
      term = Term.new(VersionConstraint.exact(version), true)
      new(term, :decision, decision_level)
    end

    def decision?
      cause == :decision
    end
  end
end
