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

    def incompatibilities_for(package, version)
      package_deps = @deps_by_version[package]
      package_versions = @package_versions[package]
      package_deps[version].map do |dep_package, dep_constraint_name|
        sorted_versions = package_versions.sort
        low = high = sorted_versions.index(version)

        # find version low such that all >= low share the same dep
        while low > 0 &&
            package_deps[sorted_versions[low - 1]][dep_package] == dep_constraint_name
          low -= 1
        end
        low =
          if low == 0
            nil
          else
            sorted_versions[low]
          end

        # find version high such that all < high share the same dep
        while high < sorted_versions.length &&
            package_deps[sorted_versions[high]][dep_package] == dep_constraint_name
          high += 1
        end
        high =
          if high == sorted_versions.length
            nil
          else
            sorted_versions[high]
          end

        range = VersionRange.new(min: low, max: high, include_min: true)

        self_constraint = VersionConstraint.new(package, range: range)

        if !@packages.include?(dep_package)
          # no such package -> this version is invalid
          cause = PubGrub::Incompatibility::InvalidDependency.new(dep_package, dep_constraint_name)
          return [Incompatibility.new([Term.new(self_constraint, true)], cause: cause)]
        end

        dep_constraint = PubGrub::RubyGems.parse_constraint(dep_package, dep_constraint_name)

        Incompatibility.new([Term.new(self_constraint, true), Term.new(dep_constraint, false)], cause: :dependency)
      end
    end
  end
end
