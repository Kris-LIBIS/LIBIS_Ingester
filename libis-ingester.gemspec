# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'libis/ingester/version'

Gem::Specification.new do |gem|
  gem.name          = 'libis-ingester'
  gem.version       = Libis::Ingester::VERSION
  gem.date          = Date.today.to_s

  gem.summary       = %q{Tool for ingesting digital documents in LIAS.}
  gem.description   = %q{This gem contains the basic elements for the LIAS Ingester solution.}

  gem.authors       = ['Kris Dekeyser']
  gem.email         = ['kris.dekeyser@libis.be']
  gem.homepage      = 'https://github.com/Kris-Libis/LIBIS_Ingester'
  gem.license       = 'MIT'

  gem.files         = `git ls-files -z`.split("\x0")
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})

  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'libis-tools', '~> 0.9'
  gem.add_runtime_dependency 'libis-format', '~> 0.9'
  gem.add_runtime_dependency 'libis-services', '~> 0.0.1'
  gem.add_runtime_dependency 'libis-workflow-mongoid', '~> 2.0.beta'
  gem.add_runtime_dependency 'mongoid-enum', '~> 0.2'
  gem.add_runtime_dependency 'rubyzip', '~> 1.1'

  gem.add_development_dependency 'bundler', '~> 1.7'
  gem.add_development_dependency 'rake', '~> 10.0'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'coveralls'

end
