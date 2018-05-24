module PubGrub
  class Incompatibility
    attr_reader :terms

    def initialize(terms)
      @terms = terms
      @terms.each do |term|
        raise "#{term.inspect} must be a term" unless term.is_a?(Term)
      end
    end

    def to_s
      "{ #{terms.map(&:to_s).join(", ")} }"
    end

    def inspect
      "#<#{self.class} #{to_s}>"
    end
  end
end
