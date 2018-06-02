require "test_helper"

module PubGrub
  class VersionSolverTest < Minitest::Test
    def assert_solution(source, result, expected)
      expected =
        expected.map do |package, version|
          source.version(package, version)
        end
      expected -= [Package.root_version]
      result   -= [Package.root_version]

      assert_equal expected, result
    end

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

      pp result
    end
  end
end
