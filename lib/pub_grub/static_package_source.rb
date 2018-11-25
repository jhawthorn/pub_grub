require 'pub_grub/package'
require 'pub_grub/version_constraint'
require 'pub_grub/incompatibility'

module PubGrub
  class StaticPackageSource
    class DSL
      def initialize(packages, root_deps)
        @packages = packages
        @root_deps = root_deps
      end

      def root(deps:)
        @root_deps.update(deps)
      end

      def add(name, version, deps: {})
        @packages << [name, version, deps]
      end
    end

    def initialize
      @root_deps = {}
      @package_list = []
      yield DSL.new(@package_list, @root_deps)

      @packages = {
        root: Package.root
      }
      @deps_by_version = {
        Package.root_version => @root_deps
      }

      @package_list.each do |name, version, deps|
        @packages[name] ||= Package.new(name)
        version = @packages[name].add_version(version)
        @deps_by_version[version] = deps
      end
    end

    def get_package(name)
      @packages[name] ||
        raise("No such package in source: #{name.inspect}")
    end
    alias_method :package, :get_package

    def version(package_name, version_name)
      package(package_name).version(version_name)
    end

    def incompatibilities_for(version)
      package = version.package
      @deps_by_version[version].map do |dep_package_name, dep_constraint_name|
        self_constraint =
          if package.versions == [version]
            VersionConstraint.any(package)
          else
            sorted_versions = package.versions.sort_by { |v| Gem::Version.new(v.name) }
            low = high = sorted_versions.index(version)

            # find version low such that all >= low share the same dep
            while low > 0 &&
                @deps_by_version[sorted_versions[low - 1]][dep_package_name] == dep_constraint_name
              low -= 1
            end
            low =
              if low == 0
                nil
              else
                Gem::Version.new(sorted_versions[low].name)
              end

            # find version high such that all < high share the same dep
            while high < sorted_versions.length &&
                @deps_by_version[sorted_versions[high]][dep_package_name] == dep_constraint_name
              high += 1
            end
            high =
              if high == sorted_versions.length
                nil
              else
                Gem::Version.new(sorted_versions[high].name)
              end

            range = VersionRange.new(min: low, max: high, include_min: true)

            VersionConstraint.new(package, range: range)
          end

        dep_package = @packages[dep_package_name]

        if !dep_package
          # no such package -> this version is invalid
          cause = PubGrub::Incompatibility::InvalidDependency.new(dep_package_name, dep_constraint_name)
          return [Incompatibility.new([Term.new(self_constraint, true)], cause: cause)]
        end

        dep_constraint = VersionConstraint.parse(dep_package, dep_constraint_name)

        Incompatibility.new([Term.new(self_constraint, true), Term.new(dep_constraint, false)], cause: :dependency)
      end
    end
  end
end
