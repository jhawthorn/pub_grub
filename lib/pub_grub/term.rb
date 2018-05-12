module PubGrub
  class Term
    attr_reader :constraint

    def initialize(constraint)
      @constraint = constraint
    end

    def package
      constraint.package
    end
  end
end
