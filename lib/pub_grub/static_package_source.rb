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

    def incompatibilities_for(version)
      package = version.package
      @deps_by_version[version].map do |dep_package_name, dep_constraint_name|
        bitmap = VersionConstraint.bitmap_matching(package) do |requesting_version|
          deps = @deps_by_version[requesting_version]
          deps && deps[dep_package_name] && deps[dep_package_name] == dep_constraint_name
        end
        description =
          if (bitmap == (1 << package.versions.length) - 1)
            "any"
          elsif (bitmap == 1 << version.id)
            version.name
          else
            "requiring #{dep_package_name} #{dep_constraint_name}"
          end
        self_constraint = VersionConstraint.new(package, description, bitmap: bitmap)

        dep_package = get_package(dep_package_name)
        dep_constraint = VersionConstraint.new(dep_package, dep_constraint_name)

        Incompatibility.new([Term.new(self_constraint, true), Term.new(dep_constraint, false)])
      end
    end
  end
end
