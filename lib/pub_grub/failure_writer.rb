module PubGrub
  class FailureWriter
    def initialize(root)
      @root = root

      # { Incompatibility => Integer }
      @derivations = {}

      # [ [ String, Integer or nil ] ]
      @lines = []

      # { Incompatibility => Integer }
      @line_numbers = {}

      count_derivations(root)
    end

    def write
      visit(@root)

      padding = @line_numbers.empty? ? 0 : "(#{@line_numbers.values.last}) ".length

      @lines.map do |message, number|
        lead = number ? "(#{number}) " : ""
        lead = lead.ljust(padding)
        "#{lead}#{message}"
      end.join("\n")
    end

    private

    def write_line(incompatibility, message, numbered:)
      if numbered
        number = @line_numbers.length + 1
        @line_numbers[incompatibility] = number
      end

      @lines << [message, number]
    end

    def visit(incompatibility, conclusion: false)
      raise unless incompatibility.conflict?

      numbered = conclusion || @derivations[incompatibility] > 1;
      conjunction = conclusion || incompatibility == @root ? "So," : "And"

      cause = incompatibility.cause

      if cause.conflict.conflict? && cause.other.conflict?
        conflict_line = @line_numbers[cause.conflict]
        other_line = @line_numbers[cause.other]

        if conflict_line && other_line
          write_line(
            incompatibility,
            "Because #{cause.conflict} (#{conflict_line}) and #{cause.other} (#{other_line}), #{incompatibility}.",
            numbered: numbered
          )
        elsif conflict_line || other_line
          with_line    = conflict_line ? cause.conflict : cause.other
          without_line = conflict_line ? cause.other : cause.conflict
          line = @line_numbers[with_line]

          visit(without_line);
          write_line(
            incompatibility,
            "#{conjunction} because #{with_line} (#{line}), #{incompatibility}.",
            numbered: numbered
          )
        else
          single_line_conflict = single_line?(cause.conflict.cause)
          single_line_other    = single_line?(cause.other.cause)

          if single_line_conflict || single_line_other
            first  = single_line_other ? cause.conflict : cause.other
            second = single_line_other ? cause.other : cause.conflict
            visit(first)
            visit(second)
            write_line(
              incompatibility,
              "Thus, #{incompatibility}.",
              numbered: numbered
            )
          else
            visit(cause.conflict, conclusion: true)
            @lines << ["", nil]
            visit(cause.other)

            write_line(
              incompatibility,
              "#{conjunction} because #{cause.conflict} (#{@line_numbers[cause.conflict]}), #{incompatibility}.",
              numbered: numbered
            )
          end
        end
      elsif cause.conflict.conflict? || cause.other.conflict?
        derived = cause.conflict.conflict? ? cause.conflict : cause.other
        ext     = cause.conflict.conflict? ? cause.other : cause.conflict

        derived_line = @line_numbers[derived]
        if derived_line
          write_line(
            incompatibility,
            "Because #{ext} and #{derived} (#{derived_line}), #{incompatibility}.",
            numbered: numbered
          )
        else
          # TODO: collapsible
          visit(derived)
          write_line(
            incompatibility,
            "#{conjunction} because #{ext}, #{incompatibility}.",
            numbered: numbered
          )
        end
      else
        write_line(
          incompatibility,
          "Because #{cause.conflict} and #{cause.other}, #{incompatibility}.",
          numbered: numbered
        )
      end
    end

    def single_line?(cause)
      !cause.conflict.conflict? && !cause.other.conflict?
    end

    def count_derivations(incompatibility)
      if @derivations.has_key?(incompatibility)
        @derivations[incompatibility] += 1
      else
        @derivations[incompatibility] = 1
        if incompatibility.conflict?
          cause = incompatibility.cause
          count_derivations(cause.conflict)
          count_derivations(cause.other)
        end
      end
    end
  end
end
