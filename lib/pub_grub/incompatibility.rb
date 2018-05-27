module PubGrub
  class Incompatibility
    attr_reader :terms

    def initialize(terms)
      @terms = cleanup_terms(terms)
    end

    def failure?
      terms.empty? || terms.length == 1 && terms[0].package.name == :root
    end

    def to_s
      "{ #{terms.map(&:to_s).join(", ")} }"
    end

    def inspect
      "#<#{self.class} #{to_s}>"
    end

    private

    def cleanup_terms(terms)
      terms.each do |term|
        raise "#{term.inspect} must be a term" unless term.is_a?(Term)
      end

      # Optimized simple cases
      return terms if terms.length <= 1
      return terms if terms.length == 2 && terms[0].package != terms[1].package

      terms.group_by(&:package).map do |package, common_terms|
        common_terms.inject do |acc, term|
          acc.intersect(term)
        end
      end
    end
  end
end
