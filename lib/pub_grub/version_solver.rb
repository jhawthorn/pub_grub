require 'pub_grub/partial_solution'
require 'pub_grub/term'
require 'pub_grub/incompatibility'
require 'pub_grub/solve_failure'

module PubGrub
  class VersionSolver
    attr_reader :source
    attr_reader :solution

    def initialize(source:)
      @source = source

      # { package => [incompatibility, ...]}
      @incompatibilities = Hash.new do |h, k|
        h[k] = []
      end

      @solution = PartialSolution.new

      add_incompatibility Incompatibility.new([
        Term.new(VersionConstraint.any(Package.root), false)
      ], cause: :root)
    end

    def solve
      next_package = Package.root

      while next_package
        propagate(next_package)

        next_package = choose_package_version
      end

      result = solution.decisions

      logger.info "Solution found after #{solution.attempted_solutions} attempts:"
      result.each do |package, version|
        logger.info "* #{package.name} #{version}"
      end

      result
    end

    private

    def propagate(initial_package)
      changed = [initial_package]
      while package = changed.shift
        @incompatibilities[package].reverse_each do |incompatibility|
          result = propagate_incompatibility(incompatibility)
          if result == :conflict
            root_cause = resolve_conflict(incompatibility)
            changed.clear
            changed << propagate_incompatibility(root_cause)
          elsif result # should be a Package
            changed << result
          end
        end
        changed.uniq!
      end
    end

    def propagate_incompatibility(incompatibility)
      unsatisfied = nil
      incompatibility.terms.each do |term|
        relation = solution.relation(term)
        if relation == :disjoint
          return nil
        elsif relation == :overlap
          # If more than one term is inconclusive, we can't deduce anything
          return nil if unsatisfied
          unsatisfied = term
        end
      end

      if !unsatisfied
        return :conflict
      end

      logger.debug("derived: #{unsatisfied.invert}")

      solution.derive(unsatisfied.invert, incompatibility)

      unsatisfied.package
    end

    def choose_package_version
      unsatisfied = solution.unsatisfied

      if unsatisfied.empty?
        logger.info "No packages unsatisfied. Solving complete!"
        return nil
      end

      unsatisfied_term, versions =
        unsatisfied.map do |term|
          range = term.constraint.range
          [term, source.versions_for(term.package, range)]
        end.min_by do |(_, v)|
          v.count
        end

      package = unsatisfied_term.package
      version = versions.first

      if version.nil?
        cause = Incompatibility::NoVersions.new(unsatisfied_term)
        add_incompatibility Incompatibility.new([unsatisfied_term], cause: cause)
        return package
      end

      conflict = false

      source.incompatibilities_for(version).each do |incompatibility|
        add_incompatibility incompatibility

        conflict ||= incompatibility.terms.all? do |term|
          term.package == package || solution.satisfies?(term)
        end
      end

      unless conflict
        logger.info("selecting #{package.name} #{version}")

        solution.decide(package, version.name)
      end

      package
    end

    def resolve_conflict(incompatibility)
      logger.info "conflict: #{incompatibility}"

      new_incompatibility = false

      while !incompatibility.failure?
        most_recent_term = nil
        most_recent_satisfier = nil
        difference = nil

        previous_level = 1

        incompatibility.terms.each do |term|
          satisfier = solution.satisfier(term)

          if most_recent_satisfier.nil?
            most_recent_term = term
            most_recent_satisfier = satisfier
          elsif most_recent_satisfier.index < satisfier.index
            previous_level = [previous_level, most_recent_satisfier.decision_level].max
            most_recent_term = term
            most_recent_satisfier = satisfier
            difference = nil
          else
            previous_level = [previous_level, satisfier.decision_level].max
          end

          if most_recent_term == term
            difference = most_recent_satisfier.term.difference(most_recent_term)
            if difference.empty?
              difference = nil
            else
              difference_satisfier = solution.satisfier(difference.inverse)
              previous_level = [previous_level, difference_satisfier.decision_level].max
            end
          end
        end

        if previous_level < most_recent_satisfier.decision_level ||
            most_recent_satisfier.decision?

          logger.info "backtracking to #{previous_level}"
          solution.backtrack(previous_level)

          if new_incompatibility
            add_incompatibility(incompatibility)
          end

          return incompatibility
        end

        new_terms = []
        new_terms += incompatibility.terms - [most_recent_term]
        new_terms += most_recent_satisfier.cause.terms.reject { |term|
          term.package == most_recent_satisfier.term.package
        }
        if difference
          new_terms << difference.invert
        end

        incompatibility = Incompatibility.new(new_terms, cause: Incompatibility::ConflictCause.new(incompatibility, most_recent_satisfier.cause))

        new_incompatibility = true

        partially = difference ? " partially" : ""
        logger.info "! #{most_recent_term} is#{partially} satisfied by #{most_recent_satisfier.term}"
        logger.info "! which is caused by #{most_recent_satisfier.cause}"
        logger.info "! thus #{incompatibility}"
      end

      raise SolveFailure.new(incompatibility)
    end

    def add_incompatibility(incompatibility)
      logger.debug("fact: #{incompatibility}");
      incompatibility.terms.each do |term|
        package = term.package
        @incompatibilities[package] << incompatibility
      end
    end

    def logger
      PubGrub.logger
    end
  end
end
