require "test_helper"

module PubGrub
  class StrategyTest < Minitest::Test
    # A broken source: versions_for returns versions all_versions_for doesn't.
    class InconsistentSource < StaticPackageSource
      def all_versions_for(package)
        super.select { |version| version.to_s == "1.0.0" }
      end

      def versions_for(package, range = VersionRange.any)
        range.select_versions(@packages[package].keys.sort)
      end
    end

    def setup
      @source = InconsistentSource.new do |s|
        s.add 'a', '1.0.0'
        s.add 'a', '2.0.0'
      end
    end

    def test_raises_on_version_missing_from_all_versions_for
      error = assert_raises(RuntimeError) do
        Strategy.new(@source).next_package_and_version({ 'a' => VersionRange.any })
      end
      assert_equal "a 2.0.0 is returned by versions_for but missing from all_versions_for", error.message
    end

    def test_raises_on_only_candidate_missing_from_all_versions_for
      range = VersionRange.new(min: Gem::Version.new("2.0.0"), include_min: true)

      assert_raises(RuntimeError) do
        Strategy.new(@source).next_package_and_version({ 'a' => range })
      end
    end
  end
end
