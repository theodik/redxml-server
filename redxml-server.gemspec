# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redxml/server/version'

Gem::Specification.new do |spec|
  spec.name          = 'redxml-server'
  spec.version       = RedXML::Server::VERSION
  spec.authors       = ['Ondřej Svoboda']
  spec.email         = ['theodik@gmail.com']
  spec.summary       = %q(RedXML is a XML database using key-value database as storage.)
  spec.description   = %q()
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']
  spec.extensions    = Dir['ext/**/extconf.rb']

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency "rake-compiler"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'coveralls'

  spec.add_runtime_dependency 'redis'
  spec.add_runtime_dependency 'nokogiri'

end
