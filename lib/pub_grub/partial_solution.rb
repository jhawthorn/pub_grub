require 'pub_grub/assignment'

module PubGrub
  class PartialSolution
    attr_reader :assignments, :decisions, :level

    def initialize
      @assignments = []

      # { Package => Package::Version }
      @decisions = {}

      # { Package => Term }
      @positive = {}

      @level = 0
    end

    def relation(term)
      package = term.package
      return :overlap if !@positive.key?(package)

      @positive[package].relation(term)
    end

    def satisfies?(term)
      relation(term) == :subset
    end

    def derive(term, cause)
      add_assignment Assignment.new(term, cause, level)
    end

    # A list of unsatisfied terms
    def unsatisfied
      @positive.values.reject do |term|
        @decisions.key?(term.package)
      end
    end

    def decide(version)
      decisions[version.package] = version
      assignment = Assignment.decision(version, level)
      add_assignment(assignment)
    end

    private

    def add_assignment(assignment)
      @assignments << assignment

      term = assignment.term
      raise "not implemented yet" unless term.positive

      package = term.package

      if @positive.key?(package)
        old_term = @positive[package]
        @positive[package] = old_term.intersect(term)
      else
        @positive[term.package] = term
      end
    end
  end
end
