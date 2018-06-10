module PubGrub
  class SolveFailure < StandardError
    def initialize(incompatibility)
      @incompatibility = incompatibility
    end

    def visit(incompatibility)
      output = []

      cause = incompatibility.cause
      case cause
      when PubGrub::Incompatibility::ConflictCause
        output << incompatibility.to_s
        output += visit(cause.incompatibility)
        output += visit(cause.satisfier)
      when :dependency
        output << "#{incompatibility} (dependency)"
      else
        raise "don't know how to deal with: #{incompatibility.cause.inspect}"
      end

      output
    end

    def to_s
      output = visit(@incompatibility)
      "\n" + output.reverse.map(&:to_s).join("\n")
    end
  end
end
