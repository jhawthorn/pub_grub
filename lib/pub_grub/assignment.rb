module PubGrub
  class Assignment
    attr_reader :term, :cause, :decision_level, :index
    def initialize(term, cause, decision_level, index)
      @term = term
      @cause = cause
      @decision_level = decision_level
      @index = index
    end

    def self.decision(version, decision_level, index)
      package = version.package
      term = Term.new(VersionConstraint.exact(package, version.name), true)
      new(term, :decision, decision_level, index)
    end

    def decision?
      cause == :decision
    end
  end
end
