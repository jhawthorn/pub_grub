require "pub_grub/package"
require "pub_grub/static_package_source"
require "pub_grub/term"
require "pub_grub/version_range"
require "pub_grub/version_constraint"
require "pub_grub/version_union"
require "pub_grub/version_solver"
require "pub_grub/incompatibility"
require 'pub_grub/solve_failure'
require 'pub_grub/failure_writer'
require 'pub_grub/version'

module PubGrub
  class << self
    attr_writer :logger

    def logger
      @logger || default_logger
    end

    private

    def default_logger
      require "logger"

      logger = ::Logger.new(STDERR)
      logger.level = $DEBUG ? ::Logger::DEBUG : ::Logger::WARN
      @logger = logger
    end
  end
end
