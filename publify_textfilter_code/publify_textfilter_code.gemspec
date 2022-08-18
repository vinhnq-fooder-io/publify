# frozen_string_literal: true

# Maintain your gem's version:
require_relative "lib/publify_textfilter_code/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "publify_textfilter_code"
  s.version     = PublifyTextfilterCode::VERSION
  s.authors     = ["Matijs van Zuijlen"]
  s.email       = ["matijs@matijs.net"]
  s.homepage    = "https://publify.github.io/"
  s.summary     = "Code text filter for the Publify blogging system."
  s.description = "Code text filter sidebar for the Publify blogging system."
  s.license     = "MIT"

  s.files       = File.open("Manifest.txt").readlines.map(&:chomp)

  s.required_ruby_version = ">= 2.5.0"

  s.add_dependency "coderay", "~> 1.1.0"
  s.add_dependency "htmlentities", "~> 4.3"
  s.add_dependency "publify_core", "~> 9.2.9"

  s.add_development_dependency "rspec-rails", "~> 4.0"
  s.add_development_dependency "simplecov", "~> 0.21.2"
  s.add_development_dependency "sqlite3"
  s.metadata["rubygems_mfa_required"] = "true"
end
