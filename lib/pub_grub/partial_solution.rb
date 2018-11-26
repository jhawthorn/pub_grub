require 'pub_grub/assignment'
require 'set'

module PubGrub
  class PartialSolution
    attr_reader :assignments, :decisions
    attr_reader :attempted_solutions

    def initialize
      reset!

      @attempted_solutions = 1
      @backtracking = false
    end

    def decision_level
      @decisions.length
    end

    def relation(term)
      package = term.package
      return :overlap if !@terms.key?(package)

      @terms[package].relation(term)
    end

    def satisfies?(term)
      relation(term) == :subset
    end

    def derive(term, cause)
      add_assignment(Assignment.new(term, cause, decision_level, assignments.length))
    end

    def satisfier(term)
      assigned_term = nil

      @assignments_by[term.package].each do |assignment|
        if assigned_term
          assigned_term = assigned_term.intersect(assignment.term)
        else
          assigned_term = assignment.term
        end

        if assigned_term.satisfies?(term)
          return assignment
        end
      end

      raise "#{term} unsatisfied"
    end

    # A list of unsatisfied terms
    def unsatisfied
      @required.reject do |package|
        @decisions.key?(package)
      end.map do |package|
        @terms[package]
      end
    end

    def decide(package, version)
      @attempted_solutions += 1 if @backtracking
      @backtracking = false;

      decisions[package] = version
      assignment = Assignment.decision(package, version.name, decision_level, assignments.length)
      add_assignment(assignment)
    end

    def backtrack(previous_level)
      @backtracking = true

      new_assignments = assignments.select do |assignment|
        assignment.decision_level <= previous_level
      end

      new_decisions = Hash[decisions.first(previous_level)]

      reset!

      @decisions = new_decisions

      new_assignments.each do |assignment|
        add_assignment(assignment)
      end
    end

    private

    def reset!
      # { Array<Assignment> }
      @assignments = []

      # { Package => Array<Assignment> }
      @assignments_by = Hash.new { |h,k| h[k] = [] }

      # { Package => Package::Version }
      @decisions = {}

      # { Package => Term }
      @terms = {}

      # { Package => Boolean }
      @required = Set.new
    end

    def add_assignment(assignment)
      @assignments << assignment
      @assignments_by[assignment.term.package] << assignment

      term = assignment.term
      package = term.package

      @required.add(package) if term.positive?

      if @terms.key?(package)
        old_term = @terms[package]
        @terms[package] = old_term.intersect(term)
      else
        @terms[term.package] = term
      end
    end
  end
end
