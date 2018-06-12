# coding: utf-8

require 'date'

lib = File.expand_path('../lib', __FILE__)
# noinspection RubyResolve
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
  spec.add_runtime_dependency 'libis-format', '~> 0.9.46'
  spec.add_runtime_dependency 'libis-services', '~> 0.1.12'
  spec.add_runtime_dependency 'libis-workflow-mongoid', '~> 2.0.beta'
  spec.add_runtime_dependency 'mongoid-enum', '~> 0.3'
  spec.add_runtime_dependency 'rubyzip', '~> 1.1'
  spec.add_runtime_dependency 'naturally', '~> 2.1'
  spec.add_runtime_dependency 'highline'
  spec.add_runtime_dependency 'double-bag-ftps'
  spec.add_runtime_dependency 'redis-namespace'
  spec.add_runtime_dependency 'filesize'
  spec.add_runtime_dependency 'time_difference'
  spec.add_runtime_dependency 'roo'
  spec.add_runtime_dependency 'roo-xls'
  spec.add_runtime_dependency 'mail'
  spec.add_runtime_dependency 'yard'
  spec.add_runtime_dependency 'htmltoword'

  # tool requirements
  spec.add_runtime_dependency 'fileutils'

  # server requirements
  spec.add_runtime_dependency 'puma'
  spec.add_runtime_dependency 'rack-cors'
  spec.add_runtime_dependency 'grape'
  spec.add_runtime_dependency 'kaminari-grape'
  spec.add_runtime_dependency 'grape-kaminari'
  spec.add_runtime_dependency 'kaminari-mongoid'
  spec.add_runtime_dependency 'grape-roar'
  spec.add_runtime_dependency 'roar'
  spec.add_runtime_dependency 'roar-contrib'
  spec.add_runtime_dependency 'roar-jsonapi'
  spec.add_runtime_dependency 'grape-swagger'
  spec.add_runtime_dependency 'grape-swagger-representable'
  spec.add_runtime_dependency 'virtus'
  spec.add_runtime_dependency 'uri-query_params'
  spec.add_runtime_dependency 'rack-jwt'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'github_changelog_generator'
  spec.add_development_dependency 'shotgun'
  spec.add_development_dependency 'racksh'

end
