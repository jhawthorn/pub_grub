require "test_helper"

require "pub_grub/rubygems"
require "rubygems/requirement"

module PubGrub
  class RubyGemsTest < Minitest::Test
    def test_ranges_match_rubygems
      requirements = %q{
        >= 0
        > 0
        < 0
        <= 0
        0
        = 0
        ~> 0
        >= 0.beta
        >= 1.0
        > 1.0
        < 1.0
        ~> 1.0
        ~> 1.0.0
        ~> 1.1
        ~> 1.1.0
        >= 2
        > 2
        < 2
      }.strip.lines.map {|r| Gem::Requirement.new(r.strip) }

      releases = %W[0 1 2 3 10 11 85]
      prereleases = %W[A a b alpha beta rc1 rc2 prerelease-1]

      versions = releases
      [releases, releases, prereleases].each do |segments|
        versions += versions.flat_map do |version|
          segments.map { |segment| "#{version}.#{segment}" }
        end
      end

      versions.uniq!
      versions.map! { |v| Gem::Version.new(v) }

      requirements.each do |requirement|
        range = PubGrub::RubyGems.requirement_to_range(requirement)
        versions.each do |version|
          if requirement.satisfied_by?(version)
            assert_includes range, version
          else
            refute_includes range, version
          end
        end
      end
    end
  end
end
