
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "pub_grub/version"

Gem::Specification.new do |spec|
  spec.name          = "pub_grub"
  spec.version       = PubGrub::VERSION
  spec.authors       = ["John Hawthorn"]
  spec.email         = ["john@hawthorn.email"]

  spec.summary       = %q{A version solver based on dart's PubGrub}
  spec.description   = %q{A version solver based on dart's PubGrub}
  spec.homepage      = "https://github.com/jhawthorn/pub_grub"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.1.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "stackprof", "~> 0.2.12"
  spec.add_development_dependency "minitest-stackprof"
  spec.add_development_dependency "logger", "~> 1.6"
end
