require 'pub_grub/partial_solution'
require 'pub_grub/term'

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

      result = solution.decisions.values

      logger.debug "Solution is:"
      result.each do |version|
        logger.debug "* #{version}"
      end

      result
    end

    private

    def propagate(initial_package)
      changed = [initial_package]
      while package = changed.shift
        @incompatibilities[package].each do |incompatibility|
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

      logger.debug "Chosing from unsatisfied: #{unsatisfied.map{|t| "#{t} (#{t.versions.count})" }.join(", ")}"

      # Pub has some smart logic and additional behaviour here
      # I'm just going to pick the first version of the first package

      version = unsatisfied.min_by do |term|
        term.versions.count
      end.versions.first

      # It would also be good to avoid making the decision if the decision will
      # cause a conflict, as pubgrub does.

      logger.info("selecting #{version}")

      solution.decide(version)

      source.incompatibilities_for(version).each do |incompatibility|
        add_incompatibility incompatibility
      end

      version.package
    end

    def resolve_conflict(incompatibility)
      logger.info "conflict: #{incompatibility}"

      new_incompatibility = false

      while !incompatibility.failure?
        current_term = nil
        current_satisfier = nil
        current_index = nil
        difference = nil

        previous_level = 1

        incompatibility.terms.each do |term|
          satisfier, index = solution.satisfier(term)

          if current_satisfier.nil?
            current_term = term
            current_satisfier = satisfier
            current_index = index
          elsif current_index < index
            previous_level = [previous_level, current_satisfier.decision_level].max
            current_satisfier = satisfier
            current_term = term
            current_index = index
            puts "clearing difference" if difference
            difference = nil
          else
            previous_level = [previous_level, current_satisfier.decision_level].max
          end

          if current_term == term
            difference = current_satisfier.term.difference(current_term)
            p difference
            p difference.normalized_constraint
            if difference.empty?
              difference = nil
            else
              difference_satisfier, _ = solution.satisfier(difference)
              previous_level = [previous_level, difference_satisfier.decision_level].max
            end
          end
        end

        if previous_level < current_satisfier.decision_level ||
            current_satisfier.cause.nil?

          puts "#{previous_level} < #{current_satisfier.decision_level}"
          puts "satisfier:"
          p current_satisfier

          logger.info "backtracking to #{previous_level}"
          solution.backtrack(previous_level)

          if new_incompatibility
            add_incompatibility(incompatibility)
          end

          return incompatibility
        end

        new_terms = []
        new_terms += incompatibility.terms - [current_term]
        new_terms += current_satisfier.cause.terms.reject { |term|
          term.package == current_satisfier.term.package
        }
        if difference
          p difference
          new_terms << difference.invert
          p new_terms
        end

        incompatibility = Incompatibility.new(new_terms, cause: Incompatibility::ConflictCause.new(incompatibility, current_satisfier.cause))

        new_incompatibility = true

        p(difference: difference)
        partially = difference ? " partially" : ""
        logger.info "! #{current_term} is#{partially} satisfied by #{current_satisfier.term}"
        logger.info "! which is caused by #{current_satisfier.cause}"
        logger.info "! thus #{incompatibility}"
      end

      raise "Solving failed!"
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
