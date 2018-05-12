module PubGrub
  class Package
    class Version
      attr_reader :package, :name

      def initialize(package, name)
        @package = package
        @name = name
      end

      def to_s
        "#{package.name} #{name}"
      end
    end

    attr_reader :name, :versions

    def initialize(name)
      @name = name
      @versions = []
    end

    def add_version(name)
      @versions << Version.new(self, name)
    end

    class RootPackage < Package
      class Version < Package::Version
        def to_s
          "(root)"
        end
      end

      def initialize
        super("(root)")
        @versions = [Version.new(self, "1.0.0")].freeze
      end
    end

    def self.root
      @root ||= RootPackage.new
    end
  end
end
