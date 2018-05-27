$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "pub_grub"

PubGrub.logger.level = Logger::DEBUG

require "minitest/autorun"
