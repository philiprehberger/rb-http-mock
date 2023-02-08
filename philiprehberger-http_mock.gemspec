# frozen_string_literal: true

require_relative 'lib/philiprehberger/http_mock/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-http_mock'
  spec.version       = Philiprehberger::HttpMock::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Lightweight HTTP request stubbing for tests'
  spec.description   = 'Stub HTTP requests in tests with a fluent API for matching methods, URLs, ' \
                       'headers, and bodies. Includes request recording and scoped isolation.'
  spec.homepage      = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-http_mock'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/philiprehberger/rb-http-mock'
  spec.metadata['changelog_uri']         = 'https://github.com/philiprehberger/rb-http-mock/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/philiprehberger/rb-http-mock/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
