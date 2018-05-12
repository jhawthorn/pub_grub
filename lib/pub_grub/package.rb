module PubGrub
  class Package
    class Version
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end

    attr_reader :name, :versions

    def initialize(name)
      @name = name
      @versions = []
    end

    def add_version(name)
      @versions << Version.new(name)
    end

    class RootPackage < Package
      def initialize
        super("(root)")
        add_version('1.0.0')
      end
    end

    def self.root
      @root ||= RootPackage.new
    end
  end
end
