module PubGrub
  class Incompatibility
    ConflictCause = Struct.new(:incompatibility, :satisfier)

    attr_reader :terms, :cause

    def initialize(terms, cause:)
      @cause = cause
      @terms = cleanup_terms(terms)
    end

    def failure?
      terms.empty? || (terms.length == 1 && terms[0].package == Package.root)
    end

    def to_s
      case cause
      when :dependency
        raise unless terms.length == 2
        "#{terms[0]} depends on #{terms[1].invert}"
      else
        # generic
        if terms.length == 1
          term = terms[0]
          if term.positive?
            "#{terms[0]} is forbidden"
          else
            "#{terms[0].invert} is required"
          end
        else
          if terms.all?(&:positive?)
            "one of #{terms.map(&:to_s).join(" or ")} must be false"
          elsif terms.all?(&:negative?)
            "one of #{terms.map(&:invert).join(" or ")} must be true";
          else
            positive = terms.select(&:positive?)
            negative = terms.select(&:negative?).map(&:invert)

            if positive.length == 1
              "#{positive[0]} requires #{negative.join(" or ")}"
            else
              "if #{positive.join(" and ")} then #{negative.join(" or ")}"
            end
          end
        end
      end
    end

    def inspect
      "#<#{self.class} #{to_s}>"
    end

    private

    def cleanup_terms(terms)
      terms.each do |term|
        raise "#{term.inspect} must be a term" unless term.is_a?(Term)
      end

      p cause
      if terms.length != 1 && ConflictCause === cause
        p terms
        terms = terms.reject do |term|
          term.positive? && term.package == Package.root
        end
        p terms
      end

      # Optimized simple cases
      return terms if terms.length <= 1
      return terms if terms.length == 2 && terms[0].package != terms[1].package

      terms.group_by(&:package).map do |package, common_terms|
        term =
          common_terms.inject do |acc, term|
          acc.intersect(term)
        end

        if term.empty?
          raise "Incompatibility should not have empty terms: #{term}"
        end

        term
      end
    end
  end
end
