# frozen_string_literal: true

module PubGrub
  class Package

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def inspect
      "#<#{self.class} #{name.inspect}>"
    end

    def <=>(other)
      name <=> other.name
    end

    def self.root
      @root ||= Package.new(:root)
    end
  end
end
