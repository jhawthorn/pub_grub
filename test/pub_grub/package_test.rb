require "test_helper"

module PubGrub
  class PackageTest < Minitest::Test
    def test_root
      package = Package.root

      assert_kind_of Package::RootPackage, package
      assert_kind_of Package, package

      assert_equal "(root)", package.name
      assert_equal 1, package.versions.length
    end
  end
end
