module PubGrub
  class SolveFailure < StandardError
    def initialize(incompatibility)
      @incompatibility = incompatibility
    end

    class Output
      def initialize(root)
        @root = root
      end
    end

    class NumberedOutput < Output
      def initialize(root)
        super(root)
        @numbers = Hash.new do |h, k|
          h[k] = h.size
        end
      end

      def visit(incompatibility)
        cause = incompatibility.cause
        if PubGrub::Incompatibility::ConflictCause === cause
          visit(cause.incompatibility)
          visit(cause.satisfier)
        end

        @numbers[incompatibility]
      end

      def list
        visit(@root)

        @numbers.map do |incompatibility, n|
          s = "#{n}. #{incompatibility}"
          cause = incompatibility.cause
          case cause
          when PubGrub::Incompatibility::ConflictCause
            s << " (##{@numbers[cause.incompatibility]} and ##{@numbers[cause.satisfier]})"
          when :dependency
            s << " (dependency)"
          else
            raise "unknown cause: #{cause.inspect}"
          end
          s
        end
      end
    end

    def to_s
      "\n" + NumberedOutput.new(@incompatibility).list.join("\n")
    end
  end
end
