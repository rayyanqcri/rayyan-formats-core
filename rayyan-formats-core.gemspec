# coding: utf-8

# developemnt instructions:
# 1- Do your modifications
# 2- Increase version number in lib/rayyan-formats-core/version.rb
# 3- gem build rayyan-formats-core.gemspec
# 4a- test the code by pointing Gemfile entry to rayyan-formats-core path
# 4b- test by: gem install rayyan-formats-core-VERSION.gem then upgrade version in Gemfile
# 5- git add, commit and push
# 6- gem push rayyan-formats-core-VERSION.gem


lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rayyan-formats-core/version'

Gem::Specification.new do |spec|
  spec.name          = "rayyan-formats-core"
  spec.version       = RayyanFormats::VERSION
  spec.authors       = ["Hossam Hammady"]
  spec.email         = ["github@hammady.net"]
  spec.description   = %q{Rayyan core plugin for import/export of reference file formats. It comes with wrapped text and CSV plugins. Similarly more formats can be supported and enabled via the initializer. }
  spec.summary       = %q{Rayyan core plugin for import/export of reference file formats}
  spec.homepage      = "https://github.com/rayyan/rayyan-formats-core"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib", "spec/shared"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency 'rake', '~> 0'
  spec.add_development_dependency 'log4r', '~> 1.0'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'simplecov', '~> 0.14'
  spec.add_development_dependency 'coderay', '~> 1.1'

end
