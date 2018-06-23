# frozen_string_literal: true

module PubGrub
  class Package
    class Version
      attr_reader :package, :id, :name

      def initialize(package, id, name)
        @package = package
        @id = id
        @name = name
      end

      def to_s
        "#{package.name} #{name}"
      end

      def inspect
        "#<#{self.class} #{package.name} #{name} (#{id})>"
      end

      def <=>(other)
        [package, id] <=> [other.package, other.id]
      end
    end

    attr_reader :name, :versions

    def initialize(name)
      @name = name
      @versions = []
      yield self if block_given?
    end

    def version(version)
      @versions.detect { |v| v.name == version } ||
        raise("No such version of #{name.inspect}: #{version.inspect}")
    end
    alias_method :[], :version

    def add_version(name)
      Version.new(self, @versions.length, name).tap do |version|
        @versions << version
      end
    end

    def inspect
      "#<#{self.class} #{name.inspect} (#{versions.count} versions)>"
    end

    def <=>(other)
      name <=> other.name
    end

    class RootPackage < Package
      class Version < Package::Version
        def to_s
          "(root)"
        end
      end

      attr_reader :version

      def initialize
        super(:root)
        @version = Version.new(self, 0, "1.0.0")
        @versions = [@version].freeze
      end
    end

    def self.root
      @root ||= RootPackage.new
    end

    def self.root_version
      root.version
    end
  end
end
