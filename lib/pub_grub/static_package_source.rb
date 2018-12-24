require 'pub_grub/package'
require 'pub_grub/version_constraint'
require 'pub_grub/incompatibility'
require 'pub_grub/basic_package_source'

module PubGrub
  class StaticPackageSource < BasicPackageSource
    class DSL
      def initialize(packages, root_deps)
        @packages = packages
        @root_deps = root_deps
      end

      def root(deps:)
        @root_deps.update(deps)
      end

      def add(name, version, deps: {})
        @packages << [name, Gem::Version.new(version), deps]
      end
    end

    def initialize
      @root_deps = {}
      @package_list = []
      yield DSL.new(@package_list, @root_deps)

      @packages = Set.new([Package.root])
      @package_versions = Hash.new { |h, k| h[k] = [] }
      @deps_by_version = Hash.new { |h, k| h[k] = {} }

      root_version = Package.root_version
      @package_versions[Package.root] = [root_version]
      @deps_by_version[Package.root][root_version] = @root_deps

      @package_list.each do |package, version, deps|
        @packages.add(package)
        @package_versions[package] << version
        @deps_by_version[package][version] = deps
      end

      super()
    end

    def all_versions_for(package)
      @package_list.select do |pkg, _, _|
        pkg == package
      end.map do |_, version, _|
        version
      end
    end

    def dependencies_for(package, version)
      @deps_by_version[package][version]
    end

    def parse_dependency(package, dependency)
      return false unless @packages.include?(package)

      PubGrub::RubyGems.parse_constraint(package, dependency)
    end
  end
end
