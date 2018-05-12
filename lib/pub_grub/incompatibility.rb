module PubGrub
  class Incompatibility
    attr_reader :terms

    def initialize(terms)
      @terms = terms
    end
  end
end
