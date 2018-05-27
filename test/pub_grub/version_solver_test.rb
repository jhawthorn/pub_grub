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

      assert_equal [
        Package.root_version,
        source.version('a', '1.0.0'),
        source.version('b', '1.0.0'),
        source.version('aa', '1.0.0'),
        source.version('ab', '1.0.0'),
        source.version('ba', '1.0.0'),
        source.version('bb', '1.0.0')
      ], result
    end

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

      assert_equal [
        Package.root_version,
        source.version('foo', '1.0.0'),
        source.version('bar', '1.0.0')
      ], result
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

      assert_equal [
        Package.root_version,
        source.version('foo', '1.0.0')
      ], result
    end
  end
end
