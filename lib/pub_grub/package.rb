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
        "#<#{self.class} #{package.name}:#{id} #{name}>"
      end
    end

    attr_reader :name, :versions

    def initialize(name)
      @name = name
      @versions = []
      yield self if block_given?
    end

    def [](version)
      @versions.detect { |v| v.name == versions } ||
        raise("No such version: #{version.inspect}")
    end

    def add_version(name)
      @versions << Version.new(self, @versions.length, name)
    end

    class RootPackage < Package
      class Version < Package::Version
        def to_s
          "(root)"
        end
      end

      def initialize
        super(:root)
        @versions = [Version.new(self, 0, "1.0.0")].freeze
      end
    end

    def self.root
      @root ||= RootPackage.new
    end
  end
end
