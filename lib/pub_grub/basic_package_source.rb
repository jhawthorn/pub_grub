require 'pub_grub/version_constraint'
require 'pub_grub/incompatibility'

module PubGrub
  class BasicPackageSource
    def initialize
      @root_package = Package.root
      @root_version = Package.root_version

      @cached_versions = Hash.new do |h,k|
        if k == @root_package
          h[k] = [0]
        else
          h[k] = all_versions_for(k)
        end
      end
      @sorted_versions = Hash.new { |h,k| h[k] = @cached_versions[k].sort }

      @cached_dependencies = Hash.new do |packages, package|
        if package == @root_package
          packages[package] = {
            @root_version => root_dependencies
          }
        else
          packages[package] = Hash.new do |versions, version|
            versions[version] = dependencies_for(package, version)
          end
        end
      end
    end

    def all_versions_for(package)
      raise NotImplementedError
    end

    def dependencies_for(package, version)
      raise NotImplementedError
    end

    def root_dependencies
      # You can override this, otherwise it will call dependencies_for with the
      # root package.
      dependencies_for(@root_package, @root_version)
    end

    def versions_for(package, range=VersionRange.any)
      @cached_versions[package].select do |version|
        range.include?(version)
      end
    end

    def incompatibilities_for(package, version)
      package_deps = @cached_dependencies[package]
      sorted_versions = @sorted_versions[package]
      package_deps[version].map do |dep_package, dep_constraint_name|
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
        end

        dep_constraint = parse_dependency(dep_package, dep_constraint_name)
        if !dep_constraint
          # falsey indicates this dependency was invalid
          cause = PubGrub::Incompatibility::InvalidDependency.new(dep_package, dep_constraint_name)
          return [Incompatibility.new([Term.new(self_constraint, true)], cause: cause)]
        elsif !dep_constraint.is_a?(VersionConstraint)
          # Upgrade range/union to VersionConstraint
          dep_constraint = VersionConstraint.new(dep_package, range: dep_constraint)
        end

        Incompatibility.new([Term.new(self_constraint, true), Term.new(dep_constraint, false)], cause: :dependency)
      end
    end
  end
end
