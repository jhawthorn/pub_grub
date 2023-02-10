require "test_helper"

module PubGrub
  class VersionSolverTest < Minitest::Test
    def test_simple_dependency_tree
      source = StaticPackageSource.new do |s|
        s.add 'a', '1.0.0', deps: { 'aa' => '1.0.0', 'ab' => '1.0.0' }
        s.add 'aa', '1.0.0'
        s.add 'ab', '1.0.0'
        s.add 'b', '1.0.0', deps: { 'ba' => '1.0.0', 'bb' => '1.0.0' }
        s.add 'ba', '1.0.0'
        s.add 'bb', '1.0.0'

        s.root deps: { 'a' => '1.0.0', 'b' => '1.0.0' }
      end

      solver = VersionSolver.new(source: source)
      result = solver.solve

      assert_solution source, result, {
        'a'  => '1.0.0',
        'b'  => '1.0.0',
        'aa' => '1.0.0',
        'ab' => '1.0.0',
        'ba' => '1.0.0',
        'bb' => '1.0.0'
      }
    end

    def test_iterative_solving
      source = StaticPackageSource.new do |s|
        s.add 'a', '1', deps: { 'b' => '1', 'c' => '1' }
        s.add 'b', '1'
        s.add 'c', '1'

        s.root deps: { 'a' => '1.0.0' }
      end

      solver = VersionSolver.new(source: source)

      assert_equal 0, solver.solution.decisions.size
      assert_equal 1, solver.solution.assignments.size
      assert_equal 1, solver.solution.unsatisfied.size
      solver.work
      assert_equal 1, solver.solution.decisions.size
      assert_equal 3, solver.solution.assignments.size
      assert_equal 1, solver.solution.unsatisfied.size
      solver.work
      assert_equal 2, solver.solution.decisions.size
      assert_equal 6, solver.solution.assignments.size
      assert_equal 2, solver.solution.unsatisfied.size
      solver.work
      assert_equal 3, solver.solution.decisions.size
      assert_equal 7, solver.solution.assignments.size
      assert_equal 1, solver.solution.unsatisfied.size
      solver.work
      assert_equal 4, solver.solution.decisions.size
      assert_equal 8, solver.solution.assignments.size
      assert_equal 0, solver.solution.unsatisfied.size

      assert_predicate solver, :solved?

      assert_solution source, solver.result, {
        'a' => '1.0.0',
        'b' => '1.0.0',
        'c' => '1.0.0'
      }
    end

    def test_shared_dependency_with_overlapping_constraints
      source = StaticPackageSource.new do |s|
        s.root deps: { 'a' => '1.0.0', 'b' => '1.0.0' }

        s.add 'a', '1.0.0', deps: { 'shared' => [ '>= 2.0.0', '<4.0.0' ] }
        s.add 'b', '1.0.0', deps: { 'shared' => [ '>= 3.0.0', '<5.0.0' ] }
        s.add 'shared', '5.0.0'
        s.add 'shared', '4.0.0'
        s.add 'shared', '3.6.9'
        s.add 'shared', '3.0.0'
        s.add 'shared', '2.0.0'
      end

      solver = VersionSolver.new(source: source)
      result = solver.solve

      assert_solution source, result, {
        'a' => '1.0.0',
        'b' => '1.0.0',
        'shared' => '3.6.9',
      }
    end

    # From https://github.com/dart-lang/pub/blob/d84173ee/test/version_solver_test.dart#L697
    def test_diamond_dependency_graph
      source = StaticPackageSource.new do |s|
        s.root deps: {
          'a' => '>= 0',
          'b' => '>= 0'
        }

        s.add 'a', '2.0.0', deps: { 'c' => '~> 1.0' }
        s.add 'a', '1.0.0'

        s.add 'b', '2.0.0', deps: { 'c' => '~> 3.0' }
        s.add 'b', '1.0.0', deps: { 'c' => '~> 2.0' }

        s.add 'c', '3.0.0'
        s.add 'c', '2.0.0'
        s.add 'c', '1.0.0'
      end

      solver = VersionSolver.new(source: source)
      result = solver.solve

      assert_solution source, result, {
        'a' => '1.0.0',
        'b' => '2.0.0',
        'c' => '3.0.0'
      }
    end


    # From https://github.com/dart-lang/pub/blob/d84173ee/test/version_solver_test.dart#L717
    # c 2.0.0 is incompatible with y 2.0.0 because it requires x 1.0.0, but that
    # requirement only exists because of both a and b. The solver should be able
    # to deduce c 2.0.0's incompatibility and select c 1.0.0 instead.
    def test_backjumps_after_a_partial_satisfier
      source = StaticPackageSource.new do |s|
        s.root deps: {
          'c' => '>= 0',
          'y' => '2.0.0'
        }

        s.add 'a', '1.0.0', deps: { 'x': '>= 1.0.0' }
        s.add 'b', '1.0.0', deps: { 'x': '< 2.0.0' }

        s.add 'c', '1.0.0'
        s.add 'c', '2.0.0', deps: { 'a': '>= 0', 'b': '>= 0' }

        s.add 'x', '0.0.0'
        s.add 'x', '1.0.0', deps: { 'y': '1.0.0' }
        s.add 'x', '2.0.0'

        s.add 'y', '1.0.0'
        s.add 'y', '2.0.0'
      end

      solver = VersionSolver.new(source: source)
      result = solver.solve

      assert_solution source, result, {
        'c' => '1.0.0',
        'y' => '2.0.0'
      }
    end

    # From pub's test suite
    def test_complex_backtrack
      source = StaticPackageSource.new do |s|
        s.root deps: {
          'foo' => '>= 0',
          'bar' => '>= 0'
        }

        # This sets up one hundred versions of foo and bar, 0.0.0 through 9.9.0. Each
        # version of foo depends on a baz with the same major version. Each version
        # of bar depends on a baz with the same minor version. There is only one
        # version of baz, 0.0.0, so only older versions of foo and bar will
        # satisfy it.
        s.add 'baz', "0.0.0"
        9.downto(0) do |i|
          9.downto(0) do |j|
            s.add 'foo', "#{i}.#{j}.0", deps: { 'baz' => "#{i}.0.0" }
            s.add 'bar', "#{i}.#{j}.0", deps: { 'baz' => "0.#{j}.0" }
          end
        end
      end

      solver = VersionSolver.new(source: source)
      result = solver.solve

      assert_solution source, result, {
        'foo' => '0.9.0',
        'bar' => '9.0.0',
        'baz' => '0.0.0'
      }
    end

    ############################################################################
    ## Examples from Pub's solver.md documentation                            ##
    ## https://github.com/dart-lang/pub/blob/master/doc/solver.md             ##
    ############################################################################

    ## First example from pub's solver.md documentation
    ## https://github.com/dart-lang/pub/blob/master/doc/solver.md#no-conflicts
    def test_no_conflicts
      source = StaticPackageSource.new do |s|
        s.add 'foo', '1.0.0', deps: { 'bar' => '1.0.0' }
        s.add 'bar', '2.0.0'
        s.add 'bar', '1.0.0'
        s.root deps: { 'foo' => '1.0.0' }
      end

      solver = VersionSolver.new(source: source)
      result = solver.solve

      assert_solution source, result, {
        'foo' => '1.0.0',
        'bar' => '1.0.0'
      }
    end

    ## Third example from pub's solver.md documentation
    ## https://github.com/dart-lang/pub/blob/master/doc/solver.md#performing-conflict-resolution
    def test_single_conflict_resolution
      source = StaticPackageSource.new do |s|
        s.root deps: { 'foo' => '>= 1.0.0' }
        s.add 'foo', '2.0.0', deps: { 'bar' => '1.0.0' }
        s.add 'foo', '1.0.0'
        s.add 'bar', '1.0.0', deps: { 'foo' => '1.0.0' }
      end

      solver = VersionSolver.new(source: source)
      result = solver.solve

      assert_solution source, result, {
        'foo' => '1.0.0'
      }
    end

    ## Fourth example from pub's solver.md documentation
    ## https://github.com/dart-lang/pub/blob/master/doc/solver.md#performing-conflict-resolution
    def test_conflict_resolution_with_partial_satisfier
      source = StaticPackageSource.new do |s|
        s.root deps: { 'foo' => '~> 1.0', 'target' => '2.0.0' }

        s.add 'foo', '1.1.0', deps: { 'right' => '~> 1.0', 'left' => '~> 1.0' }
        s.add 'foo', '1.0.0'
        s.add 'left', '1.0.0', deps: { 'shared' => '>= 1.0.0' }
        s.add 'right', '1.0.0', deps: { 'shared' => '< 2.0.0' }
        s.add 'shared', '2.0.0'
        s.add 'shared', '1.0.0', deps: { 'target' => '~> 1.0' }
        s.add 'target', '2.0.0'
        s.add 'target', '1.0.0'
      end

      solver = VersionSolver.new(source: source)
      result = solver.solve

      assert_solution source, result, {
        'foo' => '1.0.0',
        'target' => '2.0.0'
      }
    end

    ## Fifth example from pub's solver.md documentation
    ## https://github.com/dart-lang/pub/blob/master/doc/solver.md#linear-error-reporting
    def test_linear_error_reporting
      source = StaticPackageSource.new do |s|
        s.root deps: { 'foo' => '~> 1.0', 'baz' => '~> 1.0' }

        s.add 'bar', '2.0.0', deps: { 'baz' => '~> 3.0' }
        s.add 'foo', '1.0.0', deps: { 'bar' => '~> 2.0' }
        s.add 'baz', '3.0.0'
        s.add 'baz', '1.0.0'
      end

      solver = VersionSolver.new(source: source)

      ex = assert_raises PubGrub::SolveFailure do
        solver.solve
      end
      assert_equal <<ERR.strip, ex.explanation.strip
Because every version of foo depends on bar ~> 2.0
  and every version of bar depends on baz ~> 3.0,
  every version of foo requires baz ~> 3.0.
So, because root depends on foo ~> 1.0
  and root depends on baz ~> 1.0,
  version solving has failed.
ERR
    end

    ## Sixth example from pub's solver.md documentation
    ## https://github.com/dart-lang/pub/blob/master/doc/solver.md#linear-error-reporting
    def test_branching_error_reporting
      source = StaticPackageSource.new do |s|
        s.root deps: { 'foo' => '~> 1.0' }

        s.add 'foo', '1.1.0', deps: { 'y' => '~> 1.0', 'x' => '~> 1.0' }
        s.add 'foo', '1.0.0', deps: { 'b' => '~> 1.0', 'a' => '~> 1.0' }

        s.add 'a', '1.0.0', deps: { 'b' => '~> 2.0' }

        s.add 'b', '2.0.0'
        s.add 'b', '1.0.0'

        s.add 'x', '1.0.0', deps: { 'y' => '~> 2.0' }

        s.add 'y', '2.0.0'
        s.add 'y', '1.0.0'
      end

      solver = VersionSolver.new(source: source)

      ex = assert_raises PubGrub::SolveFailure do
        solver.solve
      end
      assert_equal <<ERR.strip,  ex.explanation.strip
    Because every version of a depends on b ~> 2.0
      and foo < 1.1.0 depends on b ~> 1.0,
      every version of a is incompatible with foo < 1.1.0.
(1) So, because foo < 1.1.0 depends on a ~> 1.0,
      foo < 1.1.0 cannot be used.

    Because every version of x depends on y ~> 2.0
      and foo >= 1.1.0 depends on y ~> 1.0,
      every version of x is incompatible with foo >= 1.1.0.
    And because foo >= 1.1.0 depends on x ~> 1.0,
      foo >= 1.1.0 cannot be used.
    So, because foo < 1.1.0 cannot be used (1),
      version solving has failed.
ERR
    end

    def test_invalid_package_failure
      source = StaticPackageSource.new do |s|
        s.root deps: { 'foo' => '~> 1.0' }

        s.add 'foo', '1.0.0', deps: { 'bar' => '1.0.0' }
      end

      solver = VersionSolver.new(source: source)

      ex = assert_raises PubGrub::SolveFailure do
        solver.solve
      end
      assert_equal <<ERR.strip,  ex.explanation.strip
Because every version of foo depends on unknown package bar
  and root depends on foo ~> 1.0,
  version solving has failed.
ERR
    end

    def test_invalid_package_success
      source = StaticPackageSource.new do |s|
        s.root deps: { 'foo' => '~> 1.0' }

        s.add 'foo', '1.0.1', deps: { 'baar' => '1.0.0' }
        s.add 'foo', '1.0.0', deps: { 'bar' => '1.0.0' }

        s.add 'bar', '1.0.0'
      end

      solver = VersionSolver.new(source: source)
      result = solver.solve

      assert_solution source, result, {
        'foo' => '1.0.0',
        'bar' => '1.0.0'
      }
    end

    def test_conflicts_with_empty_ranges_and_version_unions
      source = StaticPackageSource.new do |s|
        s.root deps: { 'rails' => '>= 7.0.3.1', 'activeadmin' => '2.13.1' }

        s.add 'activeadmin', '2.13.1', deps: { 'railties' => ['>= 6.1', '< 7.1'] }
        s.add "actionpack", "6.1.4"
        s.add "activesupport", "6.1.4"
        s.add "actionpack", "7.0.3.1"
        s.add "activesupport", "7.0.3.1"
        s.add "actionpack", "7.0.4"
        s.add "activesupport", "7.0.4"
        s.add "railties", "6.1.4" , deps: { "activesupport" => "6.1.4", "actionpack" => "6.1.4" }
        s.add "rails", "7.0.3.1", deps: { "activesupport" => "7.0.3.1", "railties" => "7.0.3.1" }
        s.add "rails", "7.0.4", deps: { "activesupport" => "7.0.4", "railties" => "7.0.4" }
      end

      solver = VersionSolver.new(source: source)

      ex = assert_raises PubGrub::SolveFailure do
        solver.solve
      end
      assert_equal <<ERR.strip,  ex.explanation.strip
Because rails < 7.0.4 depends on activesupport = 7.0.3.1
  and rails >= 7.0.4 depends on activesupport = 7.0.4,
  activesupport = 7.0.3.1 OR = 7.0.4 is required.
And because every version of railties depends on activesupport = 6.1.4,
  railties cannot be used.
Because rails < 7.0.4 depends on railties = 7.0.3.1
  and rails >= 7.0.4 depends on railties = 7.0.4,
  railties = 7.0.3.1 OR = 7.0.4 is required.
Thus, version solving has failed.
ERR
    end

    def test_circular_dependency
      source = StaticPackageSource.new do |s|
        s.root deps: { 'circular-dependency' => '>= 0' }

        s.add 'circular-dependency', '0.0.1', deps: { 'circular-dependency' => '>= 0' }
      end

      solver = VersionSolver.new(source: source)
      result = solver.solve

      assert_solution source, result, {
        'circular-dependency' => '0.0.1'
      }
    end
  end
end
