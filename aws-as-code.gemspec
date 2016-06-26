# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws_as_code/version'

Gem::Specification.new do |spec|
  spec.name          = "aws_as_code"
  spec.version       = AwsAsCode::VERSION
  spec.authors       = ["Konstantin Burnaev"]
  spec.email         = ["kbourn@gmail.com"]

  spec.summary       = %q{Provides a way to track your AWS infrastructure as a code in your version control system.}
  spec.homepage      = "https://github.com/bkon/aws-as-code"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
