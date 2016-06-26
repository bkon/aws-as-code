# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "aws_as_code/version"

Gem::Specification.new do |spec|
  spec.name          = "aws_as_code"
  spec.version       = AwsAsCode::VERSION
  spec.authors       = ["Konstantin Burnaev"]
  spec.email         = ["kbourn@gmail.com"]

  spec.summary       = <<EOF
Provides a way to track your AWS infrastructure as a code in your version control system.
EOF

  spec.homepage      = "https://github.com/bkon/aws-as-code"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`
                       .split("\x0")
                       .reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "cfndsl", "~> 0.9"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "cucumber", "~> 2.4"
  spec.add_development_dependency "rubocop", "~> 0.41"
  spec.add_development_dependency "guard-rspec", "~> 4.7"
  spec.add_development_dependency "guard-rubocop", "~> 1.2"
  spec.add_development_dependency "guard-cucumber", "~> 2.1"
  spec.add_development_dependency "codecov"
end
