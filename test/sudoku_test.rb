require "test_helper"

module PubGrub
  class SudokuTest < Minitest::Test
    class SudokuSource
      ALL_VERSIONS = (1..9).to_a.freeze

      def initialize(puzzle)
        @puzzle = puzzle
        @root = PubGrub::Package.root
      end

      def versions_for(package, range)
        return [0] if package == @root

        ALL_VERSIONS.select do |version|
          range.include?(version)
        end
      end

      def incompatibilities_for(package, version)
        return root_incompatibilities if package == @root

        row, col = package

        self_constraint = VersionConstraint.exact(package, version)
        self_term = Term.new(self_constraint, true)

        each_cell.reject do |other|
          other == package
        end.select do |(other_row, other_col)|
          other_row == row || other_col == col || (other_row / 3 == row / 3 && other_col / 3 == col / 3)
        end.map do |other|
          other_constraint = VersionConstraint.exact(other, version).invert

          Incompatibility.new([
            self_term,
            Term.new(other_constraint, false),
          ], cause: :dependency)
        end
      end

      def root_incompatibilities
        root_term = Term.new(VersionConstraint.any(@root), true)

        each_cell.map do |row, col|
          package = [row, col]
          cell = @puzzle[row * 9 + col]
          constraint =
            if cell == "."
              VersionConstraint.any(package)
            else
              VersionConstraint.exact(package, cell.to_i)
            end

          Incompatibility.new([root_term, Term.new(constraint, false)], cause: :dependency)
        end
      end

      def each_cell
        return enum_for(__method__) unless block_given?
        9.times do |row|
          9.times do |col|
            yield row, col
          end
        end
      end
    end

    def solve_sudoku(puzzle)
      # This particular puzzle
      source = SudokuSource.new(puzzle)

      solver = VersionSolver.new(source: source)
      result = solver.solve

      source.each_cell.map do |row, col|
        result[[row,col]]
      end.join
    end

    def test_sudoku_1
      puzzle =     "4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"
      assert_equal "417369825632158947958724316825437169791586432346912758289643571573291684164875293", solve_sudoku(puzzle)
    end

    def test_sudoku_2
      puzzle =     "85...24..72......9..4.........1.7..23.5...9...4...........8..7..17..........36.4."
      assert_equal "859612437723854169164379528986147352375268914241593786432981675617425893598736241", solve_sudoku(puzzle)
    end

    def test_unsolvable_sudoku
      puzzle =     "44....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"
      assert_raises PubGrub::SolveFailure do
        solve_sudoku(puzzle)
      end
    end
  end
end
