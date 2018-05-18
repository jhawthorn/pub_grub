require 'forwardable'

module PubGrub
  class Term
    attr_reader :constraint

    def initialize(constraint)
      @constraint = constraint
    end

    extend Forwardable
    def_delegators :@constraint, :package, :to_s, :versions
  end
end
