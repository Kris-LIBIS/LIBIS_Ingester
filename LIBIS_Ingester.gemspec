# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'libis/ingester/version'

Gem::Specification.new do |spec|
  spec.name          = 'LIBIS_Ingester'
  spec.version       = LIBIS::Ingester::VERSION
  spec.date          = Date.today.to_s

  spec.summary       = %q{Tool for ingesting digital documents in LIAS.}
  spec.description   = %q{This gem contains the basic elements for the LIAS Ingester solution.}

  spec.authors       = ['Kris Dekeyser']
  spec.email         = ['kris.dekeyser@libis.be']
  spec.homepage      = 'https://github.com/Kris-LIBIS/LIBIS_Ingester'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'coveralls'

  spec.add_runtime_dependency 'LIBIS_Tools', '0.0.1'
  spec.add_runtime_dependency 'LIBIS_Services', '0.0.1'
  spec.add_runtime_dependency 'LIBIS_Format', '0.0.1'
  spec.add_runtime_dependency 'LIBIS_Workflow_Mongoid', '2.0.beta.3'
  spec.add_runtime_dependency 'rubyzip', '>= 1.0.0'

end
