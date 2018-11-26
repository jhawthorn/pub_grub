# frozen_string_literal: true

module PubGrub
  class Package

    attr_reader :name, :versions

    def initialize(name)
      @name = name
      @versions = []
      yield self if block_given?
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
