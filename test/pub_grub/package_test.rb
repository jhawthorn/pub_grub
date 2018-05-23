require "test_helper"

module PubGrub
  class PackageTest < Minitest::Test
    def test_root
      package = Package.root

      assert_equal package, Package.root, "expected root to be a singleton"

      assert_kind_of Package::RootPackage, package
      assert_kind_of Package, package

      assert_equal :root, package.name
      assert_equal 1, package.versions.length
      assert_equal package, package.versions[0].package
      assert_equal "1.0.0", package.versions[0].name
      assert_equal "(root)", package.versions[0].to_s
    end

    def test_simple_package
      package = Package.new("pkg")

      assert_kind_of Package, package
      assert_equal "pkg", package.name

      version = package.add_version("1.0.0")
      assert_kind_of Package::Version, version
      assert_equal package, version.package
      assert_equal "1.0.0", version.name
      assert_equal "pkg 1.0.0", version.to_s
    end
  end
end
