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
      raise ArgumentError, "packages must match" if package != other.package

      if positive != other.positive
        self.class.new(normalized_constraint.intersect(other.normalized_constraint), true)
      else
        self.class.new(constraint.intersect(other.constraint), positive)
      end
    end

    def difference(other)
      puts("difference(#{inspect}, #{other.inspect})")
      intersect(other.invert)
    end

    def relation(other)
      normalized_constraint.relation(other.normalized_constraint)
    end

    def normalized_constraint
      positive ? constraint : constraint.invert
    end

    def satisfies?(other)
      raise ArgumentError, "packages must match" unless package == other.package

      relation(other) == :subset
    end

    extend Forwardable
    def_delegators :@constraint, :package
    def_delegators :normalized_constraint, :versions

    def positive?
      @positive
    end

    def negative?
      !positive?
    end

    def empty?
      positive? && constraint.empty?
    end

    def inspect
      "#<#{self.class} #{self}>"
    end
  end
end
