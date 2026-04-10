# philiprehberger-http_mock

[![Tests](https://github.com/philiprehberger/rb-http-mock/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-http-mock/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-http_mock.svg)](https://rubygems.org/gems/philiprehberger-http_mock)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-http-mock)](https://github.com/philiprehberger/rb-http-mock/commits/main)

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

Philiprehberger::HttpMock.stub(:get, "https://api.example.com/users")
  .to_return(status: 200, body: '{"users":[]}')

response = Philiprehberger::HttpMock.request(:get, "https://api.example.com/users")
response.status  # => 200
response.body    # => '{"users":[]}'
```

### POST with Body Matching

```ruby
Philiprehberger::HttpMock.stub(:post, "https://api.example.com/users")
  .with(body: '{"name":"Alice"}')
  .to_return(status: 201, body: '{"id":1}')
```

### Header Matching

```ruby
Philiprehberger::HttpMock.stub(:get, "https://api.example.com/data")
  .with(headers: { "Authorization" => "Bearer token123" })
  .to_return(status: 200, body: "secret")
```

### Response Sequences

```ruby
Philiprehberger::HttpMock.stub(:get, "https://api.example.com/flaky")
  .to_return_in_sequence([
    { status: 503, body: "unavailable" },
    { status: 200, body: "ok" }
  ])

Philiprehberger::HttpMock.request(:get, "https://api.example.com/flaky").status  # => 503
Philiprehberger::HttpMock.request(:get, "https://api.example.com/flaky").status  # => 200
Philiprehberger::HttpMock.request(:get, "https://api.example.com/flaky").status  # => 200 (repeats last)
```

### Callback Responses

```ruby
Philiprehberger::HttpMock.stub(:post, "https://api.example.com/echo")
  .to_return { |request| { status: 200, body: request.body.upcase } }

response = Philiprehberger::HttpMock.request(:post, "https://api.example.com/echo", body: "hello")
response.body  # => "HELLO"
```

### Error Simulation

```ruby
Philiprehberger::HttpMock.stub(:get, "https://api.example.com/fail")
  .to_raise(RuntimeError.new("connection refused"))

Philiprehberger::HttpMock.stub(:post, "https://api.example.com/slow")
  .to_timeout
# raises Philiprehberger::HttpMock::TimeoutError
```

### Method Shortcuts

```ruby
Philiprehberger::HttpMock.stub_get("https://api.example.com/users")
  .to_return(status: 200, body: '[]')

Philiprehberger::HttpMock.stub_post("https://api.example.com/users")
  .with(body: '{"name":"Alice"}')
  .to_return(status: 201)
```

Also available: `stub_put`, `stub_patch`, `stub_delete`.

### Last Request

```ruby
Philiprehberger::HttpMock.stub_post("https://api.example.com/users").to_return(status: 201)
Philiprehberger::HttpMock.request(:post, "https://api.example.com/users", body: '{"name":"Bob"}')

Philiprehberger::HttpMock.last_request.body  # => '{"name":"Bob"}'
```

### Stub Verification

```ruby
stub = Philiprehberger::HttpMock.stub(:get, "https://api.example.com/data")
  .to_return(status: 200)

Philiprehberger::HttpMock.request(:get, "https://api.example.com/data")

stub.called?     # => true
stub.call_count  # => 1

Philiprehberger::HttpMock.verify!  # raises UnmatchedStubError if any stub was never called
```

### Request Recording

```ruby
Philiprehberger::HttpMock.stub(:get, "https://api.example.com/data").to_return(status: 200)
Philiprehberger::HttpMock.request(:get, "https://api.example.com/data")

requests = Philiprehberger::HttpMock.requests
requests.length      # => 1
requests.first.url   # => "https://api.example.com/data"
```

### Scoped Isolation

```ruby
Philiprehberger::HttpMock.scope do
  Philiprehberger::HttpMock.stub(:get, "https://api.example.com/temp")
    .to_return(status: 200)

  # Stubs are automatically cleaned up after the block
end
```

## API

### `HttpMock`

| Method | Description |
|--------|-------------|
| `.stub(method, url)` | Create a request stub, returns a chainable stub definition |
| `.stub_get(url)` | Shorthand for `.stub(:get, url)` |
| `.stub_post(url)` | Shorthand for `.stub(:post, url)` |
| `.stub_put(url)` | Shorthand for `.stub(:put, url)` |
| `.stub_patch(url)` | Shorthand for `.stub(:patch, url)` |
| `.stub_delete(url)` | Shorthand for `.stub(:delete, url)` |
| `.request(method, url, body:, headers:)` | Simulate a request against registered stubs |
| `.requests` | Get all recorded requests |
| `.last_request` | Get the most recently recorded request |
| `.verify!` | Raise `UnmatchedStubError` if any stub was never called |
| `.reset!` | Clear all stubs and recorded requests |
| `.scope { ... }` | Execute a block with isolated stubs |

### `StubDefinition`

| Method | Description |
|--------|-------------|
| `#with(body:, headers:)` | Add matching constraints for body and/or headers |
| `#to_return(status:, body:, headers:)` | Set the response to return |
| `#to_return { \|request\| ... }` | Set a dynamic response callback |
| `#to_return_in_sequence(responses)` | Set an ordered sequence of responses |
| `#to_raise(exception)` | Raise an exception instead of returning a response |
| `#to_timeout` | Raise `TimeoutError` simulating a request timeout |
| `#call_count` | Number of times this stub has been matched |
| `#called?` | Whether this stub has been matched at least once |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-http-mock)

🐛 [Report issues](https://github.com/philiprehberger/rb-http-mock/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-http-mock/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
