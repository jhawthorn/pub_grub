require 'rubygems/requirement'

module PubGrub
  module RubyGems
    extend self

    def requirement_to_range(requirement)
      ranges = requirement.requirements.map do |(op, ver)|
        case op
        when "~>"
          # TODO: not sure this is correct for prereleases
          VersionRange.new(min: ver, max: ver.bump, include_min: true)
        when ">"
          VersionRange.new(min: ver)
        when ">="
          if ver == Gem::Version.new("0")
            VersionRange.any
          else
            VersionRange.new(min: ver, include_min: true)
          end
        when "<"
          VersionRange.new(max: ver)
        when "<="
          VersionRange.new(max: ver, include_max: true)
        when "="
          VersionRange.new(min: ver, max: ver, include_min: true, include_max: true)
        when "!="
          VersionRange.new(min: ver, max: ver, include_min: true, include_max: true).invert
        else
          raise "bad version specifier: #{op}"
        end
      end

      ranges.inject(&:intersect)
    end

    def requirement_to_constraint(package, requirement)
      PubGrub::VersionConstraint.new(package, range: requirement_to_range(requirement))
    end

    def parse_range(dep)
      requirement_to_range(Gem::Requirement.new(dep))
    end

    def parse_constraint(package, dep)
      range = parse_range(dep)
      PubGrub::VersionConstraint.new(package, range: range)
    end
  end
end
