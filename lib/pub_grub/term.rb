require 'forwardable'

module PubGrub
  class Term
    attr_reader :constraint, :positive

    def initialize(constraint, positive)
      @constraint = constraint
      @positive = positive
    end

    def to_s
      if positive
        @constraint.to_s
      else
        "not #{@constraint}"
      end
    end

    def invert
      self.class.new(@constraint, !@positive)
    end

    def intersect(other)
      new_constraint =
        if positive != other.positive
          normalized_constraint.intersect(other.normalized_constraint)
        else
          constraint.intersect(other.constraint)
        end

      self.class.new(new_constraint, positive)
    end

    def relation(other)
      normalized_constraint.relation(other.normalized_constraint)
    end

    def normalized_constraint
      positive ? constraint : constraint.invert
    end

    extend Forwardable
    def_delegators :@constraint, :package, :versions

    def positive?
      @positive
    end

    def negative?
      !positive?
    end
  end
end
