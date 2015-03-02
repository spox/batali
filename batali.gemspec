$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'batali/version'
Gem::Specification.new do |s|
  s.name = 'batali'
  s.version = Batali::VERSION.version
  s.summary = 'Magic'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'https://github.com/hw-labs/batali'
  s.description = 'Magic'
  s.require_path = 'lib'
  s.license = 'Apache 2.0'
  s.add_runtime_dependency 'grimoire'
  s.add_runtime_dependency 'bogo-cli'
  s.add_runtime_dependency 'http'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'pry'
  s.executables << 'batali'
  s.files = Dir['{lib,bin}/**/**/*'] + %w(batali.gemspec README.md CHANGELOG.md CONTRIBUTING.md LICENSE)
end
