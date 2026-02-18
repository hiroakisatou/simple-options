# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'simple-cli-options'
  spec.version       = '0.1.2'
  spec.authors       = ['HIROAKI SATOU']
  spec.email         = ['']

  spec.summary       = 'A small Ruby library for parsing command-line flags (short and long options with values).'
  spec.description   = <<~DESC
    simple-cli-options is a small Ruby library for parsing command-line flags with validation and conversion.
    Define options with short/long forms, then parse ARGV and read values by name.
    This gem is currently in BETA; APIs may change in future releases.
  DESC
  spec.homepage      = 'https://github.com/hiroakisatou/simple-options'
  spec.required_ruby_version = '>= 3.0.0'
  spec.licenses      = ['MIT']

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/hiroakisatou/simple-options'
  spec.metadata['changelog_uri']  = 'https://github.com/hiroakisatou/simple-options/blob/main/README.md'

  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']
  spec.executables   = []

  spec.add_runtime_dependency 'sorbet-runtime', '>= 0.5'
end
