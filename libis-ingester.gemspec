# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'libis/ingester/version'

Gem::Specification.new do |spec|
  spec.name          = 'libis-ingester'
  spec.version       = Libis::Ingester::VERSION
  spec.date          = Date.today.to_s

  spec.summary       = %q{Tool for ingesting digital documents in LIAS.}
  spec.description   = %q{This gem contains the basic elements for the LIAS Ingester solution.}

  spec.authors       = ['Kris Dekeyser']
  spec.email         = ['kris.dekeyser@libis.be']
  spec.homepage      = 'https://github.com/Kris-Libis/LIBIS_Ingester'
  spec.license       = 'MIT'

  spec.platform     = Gem::Platform::JAVA if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'

  spec.files         = `git ls-files -z`.split("\x0").delete_if {|name| name =~ /^(spec\/|\.travis|\.git)/ }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'libis-tools', '~> 0.9'
  spec.add_runtime_dependency 'libis-format', '~> 0.9'
  spec.add_runtime_dependency 'libis-services', '~> 0.0'
  spec.add_runtime_dependency 'libis-workflow-mongoid', '~> 2.0.beta'
  spec.add_runtime_dependency 'mongoid-enum', '~> 0.3'
  spec.add_runtime_dependency 'rubyzip', '~> 1.1'
  spec.add_runtime_dependency 'naturally', '~> 2.1'
  spec.add_runtime_dependency 'highline'
  spec.add_runtime_dependency 'double-bag-ftps'
  spec.add_runtime_dependency 'redis-namespace'
  spec.add_runtime_dependency 'filesize'
  spec.add_runtime_dependency 'time_difference'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'github_changelog_generator'

end
