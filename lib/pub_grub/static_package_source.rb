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
        self_constraint = VersionConstraint.exact(version)

        dep_package = @packages[dep_package_name]

        if !dep_package
          # no such package -> this version is invalid
          description = "referencing invalid package #{dep_package_name.inspect}"
          constraint = VersionConstraint.new(package, description, bitmap: bitmap)
          return [Incompatibility.new([Term.new(constraint, true)], cause: :invalid_dependency)]
        end

        dep_constraint = VersionConstraint.parse(dep_package, dep_constraint_name)

        Incompatibility.new([Term.new(self_constraint, true), Term.new(dep_constraint, false)], cause: :dependency)
      end
    end
  end
end
