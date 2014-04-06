# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'starlight_fast_gettext/version'

Gem::Specification.new do |spec|
  spec.name          = "starlight_fast_gettext"
  spec.version       = StarlightFastGettext::VERSION
  spec.authors       = ["Ivan Stana"]
  spec.email         = ["stiipa@centrum.sk"]
  spec.summary       = %q{Extract, save (YAML), process, import and export (Excel) your FastGettext translations.}
  spec.description   = %q{Simple gem for managing FastGettext translations. It is able to extract translations
from source code, show untranslated, missing and unused translations and import and export from/to Excel spreadsheet.}
  spec.homepage      = "https://github.com/istana/starlight_fast_gettext"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "roo"
  spec.add_dependency "axlsx"
  spec.add_dependency "activesupport", "~> 4.0"
  
  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
