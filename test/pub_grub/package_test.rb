require "test_helper"

module PubGrub
  class PackageTest < Minitest::Test
    def test_root
      package = Package.root

      assert_kind_of Package::RootPackage, package
      assert_kind_of Package, package

      assert_equal "(root)", package.name
      assert_equal 1, package.versions.length
      assert_equal package, package.versions[0].package
      assert_equal "1.0.0", package.versions[0].name
      assert_equal "(root)", package.versions[0].to_s
    end
  end
end
