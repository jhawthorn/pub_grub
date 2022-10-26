require "test_helper"

module PubGrub
  class PackageTest < Minitest::Test
    def test_root
      package = Package.root

      assert_equal package, Package.root, "expected root to be a singleton"

      assert_kind_of Package, package

      assert_equal :root, package.name
    end

    def test_simple_package
      package = Package.new("pkg")

      assert_kind_of Package, package
      assert_equal "pkg", package.name
      refute Package.root?(package)
    end

    def test_custom_package
      package_class = Struct.new(:name, :root) do
        def root?
          root == true
        end
      end

      refute Package.root?(package_class.new("pkg", false))
      assert Package.root?(package_class.new("pkg", true))
    end
  end
end
