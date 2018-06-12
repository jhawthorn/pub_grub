require 'test_helper'

module PubGrub
  class TermTest < Minitest::Test
    def setup
      @package = Package.new("pkg") do |p|
        p.add_version "2.0.0"
        p.add_version "1.1.0"
        p.add_version "1.0.0"
      end
    end

    def build_term(constraint, positive = true)
      constraint = VersionConstraint.new(@package, constraint)
      Term.new(constraint, positive)
    end

    def test_simple_positive_term
      term = build_term("~> 1.0")

      assert_equal "pkg ~> 1.0", term.to_s
      assert_equal 0b110, term.normalized_constraint.bitmap
      assert term.positive?
      refute term.negative?
      refute term.empty?
    end

    def test_invert_simple_term
      term = build_term("~> 1.0").invert

      assert_equal "not pkg ~> 1.0", term.to_s
      assert_equal 0b001, term.normalized_constraint.bitmap
      refute term.positive?
      assert term.negative?
      refute term.empty?
    end

    def test_intersect_negatives
      a = build_term("1.0.0", false)
      b = build_term("2.0.0", false)

      term = a.intersect(b)

      assert_equal "not pkg 1.0.0 OR 2.0.0", term.to_s
      assert_equal 0b010, term.normalized_constraint.bitmap
      refute term.empty?
    end

    def assert_term_relation(relation, a, b)
      a = build_term(a) unless a.is_a?(Term)
      b = build_term(b) unless b.is_a?(Term)
      assert_equal relation, a.relation(b)
    end

    def test_relations_positive
      assert_term_relation :subset, '1.0.0', '>= 0'
      assert_term_relation :subset, '1.1.0', '>= 0'
      assert_term_relation :subset, '2.0.0', '>= 0'
      assert_term_relation :subset, '!= 1.1.0', '>= 0'

      assert_term_relation :disjoint, '< 1.1', '> 1.1'
      assert_term_relation :disjoint, '< 1.1', '>= 1.1'
      assert_term_relation :disjoint, '<= 1.1', '> 1.1'

      assert_term_relation :overlap, '>= 0', '1.0.0'
      assert_term_relation :overlap, '>= 0', '1.1.0'
      assert_term_relation :overlap, '>= 0', '2.0.0'
      assert_term_relation :overlap, '<= 1.1', '>= 1.1'
    end

    def test_relations_pos_neg
      assert_term_relation :subset,   build_term('~> 2.0'), build_term('~> 1.0', false)
      assert_term_relation :disjoint, build_term('~> 1.1'), build_term('~> 1.0', false)
      assert_term_relation :overlap,  build_term('~> 1.0'), build_term('~> 1.1', false)
    end

    def test_relations_neg_pos
      assert_term_relation :disjoint, build_term('~> 1.0', false), build_term('~> 1.0')
      assert_term_relation :overlap,  build_term('~> 1.1', false), build_term('~> 1.0')
      assert_term_relation :overlap,  build_term('~> 2.0', false), build_term('~> 1.1')
    end

    def test_relations_neg_neg
      assert_term_relation :subset, build_term('~> 1.0', false), build_term('~> 1.1', false)
      assert_term_relation :overlap, build_term('~> 2.0', false), build_term('~> 1.0', false)
      assert_term_relation :overlap, build_term('~> 1.1', false), build_term('~> 1.0', false)
    end
  end
end
