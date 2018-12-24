require 'pub_grub/version_constraint'
require 'pub_grub/incompatibility'

module PubGrub
  class BasicPackageSource
    def initialize
      @root_package = Package.root
      @root_version = Package.root_version

      @cached_versions = Hash.new { |h,k| h[k] = all_versions_for(k) }
      @sorted_versions = Hash.new { |h,k| h[k] = all_versions_for(k) }
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
      if package == Package.root
        [0]
      else
        @cached_versions[package].select do |version|
          range.include?(version)
        end
      end
    end
  end
end
