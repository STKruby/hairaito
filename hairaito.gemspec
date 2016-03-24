# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hairaito/version'

Gem::Specification.new do |spec|
  spec.name          = 'hairaito'
  spec.version       = Hairaito::VERSION
  spec.authors       = ['Denis Mazilov']
  spec.email         = ['denis.mazilov@gmail.com']
  spec.summary       = %q{Extends Nokogiri with text snippets highlighting.}
  spec.description   = %q{}
  spec.homepage      = 'https://github.com/dmazilov/hairaito'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'

  spec.add_dependency 'nokogiri'
end
