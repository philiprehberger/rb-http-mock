# philiprehberger-http_mock

[![Tests](https://github.com/philiprehberger/rb-http-mock/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-http-mock/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-http_mock.svg)](https://rubygems.org/gems/philiprehberger-http_mock)
[![License](https://img.shields.io/github/license/philiprehberger/rb-http-mock)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

Lightweight HTTP request stubbing for tests

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-http_mock"
```

Or install directly:

```bash
gem install philiprehberger-http_mock
```

## Usage

```ruby
require "philiprehberger/http_mock"

Philiprehberger::HttpMock.stub(:get, 'https://api.example.com/users')
  .to_return(status: 200, body: '{"users":[]}')

response = Philiprehberger::HttpMock.request(:get, 'https://api.example.com/users')
response.status  # => 200
response.body    # => '{"users":[]}'
```

### POST with Body Matching

```ruby
Philiprehberger::HttpMock.stub(:post, 'https://api.example.com/users')
  .with(body: '{"name":"Alice"}')
  .to_return(status: 201, body: '{"id":1}')
```

### Header Matching

```ruby
Philiprehberger::HttpMock.stub(:get, 'https://api.example.com/data')
  .with(headers: { 'Authorization' => 'Bearer token123' })
  .to_return(status: 200, body: 'secret')
```

### Request Recording

```ruby
Philiprehberger::HttpMock.stub(:get, 'https://api.example.com/data').to_return(status: 200)
Philiprehberger::HttpMock.request(:get, 'https://api.example.com/data')

requests = Philiprehberger::HttpMock.requests
requests.length      # => 1
requests.first.url   # => "https://api.example.com/data"
```

### Scoped Isolation

```ruby
Philiprehberger::HttpMock.scope do
  Philiprehberger::HttpMock.stub(:get, 'https://api.example.com/temp')
    .to_return(status: 200)

  # Stubs are automatically cleaned up after the block
end
```

### Reset

```ruby
Philiprehberger::HttpMock.reset!
```

## API

| Method | Description |
|--------|-------------|
| `HttpMock.stub(method, url)` | Create a request stub, returns a chainable stub definition |
| `StubDefinition#with(body:, headers:)` | Add matching constraints for body and/or headers |
| `StubDefinition#to_return(status:, body:, headers:)` | Set the response to return |
| `HttpMock.request(method, url, body:, headers:)` | Simulate a request against registered stubs |
| `HttpMock.requests` | Get all recorded requests |
| `HttpMock.reset!` | Clear all stubs and recorded requests |
| `HttpMock.scope { ... }` | Execute a block with isolated stubs |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
