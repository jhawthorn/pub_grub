require "test_helper"

module PubGrub
  class VersionSolverTest < Minitest::Test
    def test_empty
      source = Minitest::Mock.new
      root = Minitest::Mock.new
      solver = VersionSolver.new(
        source: source,
        root: root
      )
    end
  end
end
