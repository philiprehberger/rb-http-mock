# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::HttpMock do
  before { Philiprehberger::HttpMock.reset! }

  it 'has a version number' do
    expect(Philiprehberger::HttpMock::VERSION).not_to be_nil
  end

  describe '.stub and .request' do
    it 'returns a stubbed response for a GET request' do
      described_class.stub(:get, 'https://api.example.com/users').to_return(status: 200, body: '{"users":[]}')

      response = described_class.request(:get, 'https://api.example.com/users')
      expect(response.status).to eq(200)
      expect(response.body).to eq('{"users":[]}')
    end

    it 'returns a stubbed response for a POST request' do
      described_class.stub(:post, 'https://api.example.com/users').to_return(status: 201, body: '{"id":1}')

      response = described_class.request(:post, 'https://api.example.com/users')
      expect(response.status).to eq(201)
      expect(response.body).to eq('{"id":1}')
    end

    it 'raises an error for unmatched requests' do
      expect do
        described_class.request(:get, 'https://api.example.com/unknown')
      end.to raise_error(Philiprehberger::HttpMock::UnmatchedRequestError)
    end

    it 'returns default 200 response when to_return is not called' do
      described_class.stub(:get, 'https://api.example.com/health')

      response = described_class.request(:get, 'https://api.example.com/health')
      expect(response.status).to eq(200)
      expect(response.body).to eq('')
    end

    it 'returns response headers' do
      described_class.stub(:get, 'https://api.example.com/data')
                     .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      response = described_class.request(:get, 'https://api.example.com/data')
      expect(response.headers).to eq({ 'Content-Type' => 'application/json' })
    end

    it 'stubs a PUT request' do
      described_class.stub(:put, 'https://api.example.com/users/1')
                     .to_return(status: 200, body: '{"updated":true}')

      response = described_class.request(:put, 'https://api.example.com/users/1')
      expect(response.status).to eq(200)
      expect(response.body).to eq('{"updated":true}')
    end

    it 'stubs a DELETE request' do
      described_class.stub(:delete, 'https://api.example.com/users/1')
                     .to_return(status: 204, body: '')

      response = described_class.request(:delete, 'https://api.example.com/users/1')
      expect(response.status).to eq(204)
      expect(response.body).to eq('')
    end

    it 'stubs a PATCH request' do
      described_class.stub(:patch, 'https://api.example.com/users/1')
                     .to_return(status: 200, body: '{"patched":true}')

      response = described_class.request(:patch, 'https://api.example.com/users/1')
      expect(response.status).to eq(200)
    end

    it 'stubs a HEAD request' do
      described_class.stub(:head, 'https://api.example.com/ping')
                     .to_return(status: 200, headers: { 'X-Custom' => 'yes' })

      response = described_class.request(:head, 'https://api.example.com/ping')
      expect(response.status).to eq(200)
      expect(response.headers['X-Custom']).to eq('yes')
    end

    it 'stubs an OPTIONS request' do
      described_class.stub(:options, 'https://api.example.com/cors')
                     .to_return(status: 200, headers: { 'Allow' => 'GET, POST' })

      response = described_class.request(:options, 'https://api.example.com/cors')
      expect(response.headers['Allow']).to eq('GET, POST')
    end

    it 'returns a 404 status code' do
      described_class.stub(:get, 'https://api.example.com/missing')
                     .to_return(status: 404, body: 'Not Found')

      response = described_class.request(:get, 'https://api.example.com/missing')
      expect(response.status).to eq(404)
      expect(response.body).to eq('Not Found')
    end

    it 'returns a 500 status code' do
      described_class.stub(:get, 'https://api.example.com/error')
                     .to_return(status: 500, body: 'Internal Server Error')

      response = described_class.request(:get, 'https://api.example.com/error')
      expect(response.status).to eq(500)
    end

    it 'returns multiple headers' do
      described_class.stub(:get, 'https://api.example.com/multi')
                     .to_return(status: 200, headers: {
                                  'Content-Type' => 'application/json',
                                  'X-Request-Id' => 'abc123',
                                  'Cache-Control' => 'no-cache'
                                })

      response = described_class.request(:get, 'https://api.example.com/multi')
      expect(response.headers.size).to eq(3)
      expect(response.headers['X-Request-Id']).to eq('abc123')
    end

    it 'includes the method and URL in unmatched error message' do
      expect do
        described_class.request(:post, 'https://api.example.com/nowhere')
      end.to raise_error(Philiprehberger::HttpMock::UnmatchedRequestError, /POST.*nowhere/)
    end
  end

  describe '.stub with .with constraints' do
    it 'matches by request body' do
      described_class.stub(:post, 'https://api.example.com/users')
                     .with(body: '{"name":"Alice"}')
                     .to_return(status: 201, body: '{"id":1}')

      response = described_class.request(:post, 'https://api.example.com/users', body: '{"name":"Alice"}')
      expect(response.status).to eq(201)
    end

    it 'does not match when body differs' do
      described_class.stub(:post, 'https://api.example.com/users')
                     .with(body: '{"name":"Alice"}')
                     .to_return(status: 201)

      expect do
        described_class.request(:post, 'https://api.example.com/users', body: '{"name":"Bob"}')
      end.to raise_error(Philiprehberger::HttpMock::UnmatchedRequestError)
    end

    it 'matches by request headers' do
      described_class.stub(:get, 'https://api.example.com/data')
                     .with(headers: { 'Authorization' => 'Bearer token123' })
                     .to_return(status: 200, body: 'secret')

      response = described_class.request(
        :get, 'https://api.example.com/data',
        headers: { 'Authorization' => 'Bearer token123' }
      )
      expect(response.body).to eq('secret')
    end

    it 'does not match when required headers are missing' do
      described_class.stub(:get, 'https://api.example.com/secure')
                     .with(headers: { 'Authorization' => 'Bearer xyz' })
                     .to_return(status: 200)

      expect do
        described_class.request(:get, 'https://api.example.com/secure')
      end.to raise_error(Philiprehberger::HttpMock::UnmatchedRequestError)
    end

    it 'matches by both body and headers together' do
      described_class.stub(:post, 'https://api.example.com/data')
                     .with(body: '{"ok":true}', headers: { 'Content-Type' => 'application/json' })
                     .to_return(status: 200, body: 'matched')

      response = described_class.request(
        :post, 'https://api.example.com/data',
        body: '{"ok":true}',
        headers: { 'Content-Type' => 'application/json' }
      )
      expect(response.body).to eq('matched')
    end
  end

  describe '.requests' do
    it 'records all requests' do
      described_class.stub(:get, 'https://api.example.com/a').to_return(status: 200)
      described_class.stub(:post, 'https://api.example.com/b').to_return(status: 201)

      described_class.request(:get, 'https://api.example.com/a')
      described_class.request(:post, 'https://api.example.com/b', body: 'data')

      requests = described_class.requests
      expect(requests.length).to eq(2)
      expect(requests[0].method).to eq(:get)
      expect(requests[0].url).to eq('https://api.example.com/a')
      expect(requests[1].method).to eq(:post)
      expect(requests[1].body).to eq('data')
    end

    it 'returns an empty array when no requests have been made' do
      expect(described_class.requests).to eq([])
    end

    it 'records request headers' do
      described_class.stub(:get, 'https://api.example.com/h')
                     .to_return(status: 200)

      described_class.request(:get, 'https://api.example.com/h', headers: { 'Accept' => 'text/html' })

      req = described_class.requests.first
      expect(req.headers['Accept']).to eq('text/html')
    end

    it 'returns a copy that does not affect internal state' do
      described_class.stub(:get, 'https://api.example.com/x').to_return(status: 200)
      described_class.request(:get, 'https://api.example.com/x')

      requests = described_class.requests
      requests.clear
      expect(described_class.requests.length).to eq(1)
    end
  end

  describe '.reset!' do
    it 'clears all stubs and recorded requests' do
      described_class.stub(:get, 'https://api.example.com/data').to_return(status: 200)
      described_class.request(:get, 'https://api.example.com/data')

      described_class.reset!

      expect(described_class.requests).to be_empty
      expect do
        described_class.request(:get, 'https://api.example.com/data')
      end.to raise_error(Philiprehberger::HttpMock::UnmatchedRequestError)
    end

    it 'can be called multiple times safely' do
      described_class.reset!
      described_class.reset!
      expect(described_class.requests).to be_empty
    end
  end

  describe '.scope' do
    it 'isolates stubs within the block' do
      described_class.stub(:get, 'https://api.example.com/outer').to_return(status: 200)

      described_class.scope do
        described_class.stub(:get, 'https://api.example.com/inner').to_return(status: 200)

        response = described_class.request(:get, 'https://api.example.com/inner')
        expect(response.status).to eq(200)

        expect do
          described_class.request(:get, 'https://api.example.com/outer')
        end.to raise_error(Philiprehberger::HttpMock::UnmatchedRequestError)
      end

      response = described_class.request(:get, 'https://api.example.com/outer')
      expect(response.status).to eq(200)
    end

    it 'restores outer stubs even if block raises' do
      described_class.stub(:get, 'https://api.example.com/safe').to_return(status: 200)

      begin
        described_class.scope { raise 'boom' }
      rescue RuntimeError
        nil
      end

      response = described_class.request(:get, 'https://api.example.com/safe')
      expect(response.status).to eq(200)
    end
  end

  describe 'stub with regex URL' do
    it 'matches URLs by regex' do
      described_class.stub(:get, %r{/users/\d+}).to_return(status: 200, body: '{"id":1}')

      response = described_class.request(:get, 'https://api.example.com/users/42')
      expect(response.status).to eq(200)
    end

    it 'does not match URLs that do not fit the regex' do
      described_class.stub(:get, %r{/users/\d+$}).to_return(status: 200)

      expect do
        described_class.request(:get, 'https://api.example.com/posts/42')
      end.to raise_error(Philiprehberger::HttpMock::UnmatchedRequestError)
    end

    it 'matches multiple URLs with the same regex' do
      described_class.stub(:get, %r{/items/\d+}).to_return(status: 200, body: 'item')

      r1 = described_class.request(:get, 'https://api.example.com/items/1')
      r2 = described_class.request(:get, 'https://api.example.com/items/999')
      expect(r1.body).to eq('item')
      expect(r2.body).to eq('item')
    end
  end

  describe 'last stub wins' do
    it 'uses the most recently registered matching stub' do
      described_class.stub(:get, 'https://api.example.com/data').to_return(status: 200, body: 'first')
      described_class.stub(:get, 'https://api.example.com/data').to_return(status: 200, body: 'second')

      response = described_class.request(:get, 'https://api.example.com/data')
      expect(response.body).to eq('second')
    end
  end

  describe '.to_return_in_sequence' do
    it 'cycles through responses in order' do
      described_class.stub(:get, 'https://api.example.com/seq')
                     .to_return_in_sequence([
                                              { status: 200, body: 'first' },
                                              { status: 201, body: 'second' },
                                              { status: 503, body: 'error' }
                                            ])

      r1 = described_class.request(:get, 'https://api.example.com/seq')
      r2 = described_class.request(:get, 'https://api.example.com/seq')
      r3 = described_class.request(:get, 'https://api.example.com/seq')

      expect(r1.status).to eq(200)
      expect(r1.body).to eq('first')
      expect(r2.status).to eq(201)
      expect(r2.body).to eq('second')
      expect(r3.status).to eq(503)
      expect(r3.body).to eq('error')
    end

    it 'repeats the last response after exhausting the sequence' do
      described_class.stub(:get, 'https://api.example.com/retry')
                     .to_return_in_sequence([
                                              { status: 200, body: 'ok' },
                                              { status: 503, body: 'error' }
                                            ])

      described_class.request(:get, 'https://api.example.com/retry')
      described_class.request(:get, 'https://api.example.com/retry')
      r3 = described_class.request(:get, 'https://api.example.com/retry')
      r4 = described_class.request(:get, 'https://api.example.com/retry')

      expect(r3.status).to eq(503)
      expect(r3.body).to eq('error')
      expect(r4.status).to eq(503)
      expect(r4.body).to eq('error')
    end

    it 'uses default values for omitted response keys' do
      described_class.stub(:get, 'https://api.example.com/defaults')
                     .to_return_in_sequence([{ status: 204 }, { body: 'hello' }])

      r1 = described_class.request(:get, 'https://api.example.com/defaults')
      r2 = described_class.request(:get, 'https://api.example.com/defaults')

      expect(r1.status).to eq(204)
      expect(r1.body).to eq('')
      expect(r2.status).to eq(200)
      expect(r2.body).to eq('hello')
    end

    it 'supports headers in sequence responses' do
      described_class.stub(:get, 'https://api.example.com/hseq')
                     .to_return_in_sequence([
                                              { status: 200, headers: { 'X-Step' => '1' } },
                                              { status: 200, headers: { 'X-Step' => '2' } }
                                            ])

      r1 = described_class.request(:get, 'https://api.example.com/hseq')
      r2 = described_class.request(:get, 'https://api.example.com/hseq')

      expect(r1.headers['X-Step']).to eq('1')
      expect(r2.headers['X-Step']).to eq('2')
    end

    it 'works with a single response in the sequence' do
      described_class.stub(:get, 'https://api.example.com/single')
                     .to_return_in_sequence([{ status: 418, body: 'teapot' }])

      r1 = described_class.request(:get, 'https://api.example.com/single')
      r2 = described_class.request(:get, 'https://api.example.com/single')

      expect(r1.status).to eq(418)
      expect(r2.status).to eq(418)
    end
  end

  describe 'stub verification' do
    describe 'StubDefinition#call_count and #called?' do
      it 'starts with call_count of 0 and called? false' do
        stub = described_class.stub(:get, 'https://api.example.com/track')
                              .to_return(status: 200)

        expect(stub.call_count).to eq(0)
        expect(stub.called?).to be(false)
      end

      it 'increments call_count on each matching request' do
        stub = described_class.stub(:get, 'https://api.example.com/track')
                              .to_return(status: 200)

        described_class.request(:get, 'https://api.example.com/track')
        expect(stub.call_count).to eq(1)
        expect(stub.called?).to be(true)

        described_class.request(:get, 'https://api.example.com/track')
        expect(stub.call_count).to eq(2)
      end

      it 'does not increment call_count for non-matching requests' do
        stub = described_class.stub(:get, 'https://api.example.com/a')
                              .to_return(status: 200)
        described_class.stub(:get, 'https://api.example.com/b')
                       .to_return(status: 200)

        described_class.request(:get, 'https://api.example.com/b')

        expect(stub.call_count).to eq(0)
        expect(stub.called?).to be(false)
      end
    end

    describe '.verify!' do
      it 'passes when all stubs have been called' do
        described_class.stub(:get, 'https://api.example.com/a').to_return(status: 200)
        described_class.stub(:post, 'https://api.example.com/b').to_return(status: 201)

        described_class.request(:get, 'https://api.example.com/a')
        described_class.request(:post, 'https://api.example.com/b')

        expect { described_class.verify! }.not_to raise_error
      end

      it 'raises UnmatchedStubError when a stub was never called' do
        described_class.stub(:get, 'https://api.example.com/unused').to_return(status: 200)

        expect do
          described_class.verify!
        end.to raise_error(Philiprehberger::HttpMock::UnmatchedStubError, /GET.*unused/)
      end

      it 'lists all uncalled stubs in the error message' do
        described_class.stub(:get, 'https://api.example.com/one').to_return(status: 200)
        described_class.stub(:post, 'https://api.example.com/two').to_return(status: 200)

        expect do
          described_class.verify!
        end.to raise_error(Philiprehberger::HttpMock::UnmatchedStubError, /GET.*one.*POST.*two/)
      end

      it 'passes when no stubs are registered' do
        expect { described_class.verify! }.not_to raise_error
      end

      it 'works within scope blocks' do
        described_class.scope do
          described_class.stub(:get, 'https://api.example.com/scoped').to_return(status: 200)

          expect do
            described_class.verify!
          end.to raise_error(Philiprehberger::HttpMock::UnmatchedStubError)

          described_class.request(:get, 'https://api.example.com/scoped')
          expect { described_class.verify! }.not_to raise_error
        end
      end
    end
  end

  describe 'callback responses' do
    it 'generates a dynamic response from a block' do
      described_class.stub(:post, 'https://api.example.com/echo')
                     .to_return { |request| { status: 200, body: request.body.upcase } }

      response = described_class.request(:post, 'https://api.example.com/echo', body: 'hello')
      expect(response.status).to eq(200)
      expect(response.body).to eq('HELLO')
    end

    it 'receives the full request object including headers' do
      described_class.stub(:get, 'https://api.example.com/mirror')
                     .to_return { |request| { status: 200, body: request.headers['X-Echo'] } }

      response = described_class.request(
        :get, 'https://api.example.com/mirror',
        headers: { 'X-Echo' => 'reflected' }
      )
      expect(response.body).to eq('reflected')
    end

    it 'receives the request URL' do
      described_class.stub(:get, %r{/items/\d+})
                     .to_return { |request| { status: 200, body: "URL: #{request.url}" } }

      response = described_class.request(:get, 'https://api.example.com/items/42')
      expect(response.body).to eq('URL: https://api.example.com/items/42')
    end

    it 'uses default values for omitted response keys' do
      described_class.stub(:get, 'https://api.example.com/partial')
                     .to_return { |_request| { body: 'just body' } }

      response = described_class.request(:get, 'https://api.example.com/partial')
      expect(response.status).to eq(200)
      expect(response.body).to eq('just body')
      expect(response.headers).to eq({})
    end

    it 'supports returning custom headers from the callback' do
      described_class.stub(:get, 'https://api.example.com/custom')
                     .to_return { |_request| { status: 200, body: 'ok', headers: { 'X-Dynamic' => 'yes' } } }

      response = described_class.request(:get, 'https://api.example.com/custom')
      expect(response.headers['X-Dynamic']).to eq('yes')
    end

    it 'tracks call_count for callback stubs' do
      stub = described_class.stub(:get, 'https://api.example.com/cb')
                            .to_return { |_request| { status: 200, body: 'ok' } }

      described_class.request(:get, 'https://api.example.com/cb')
      described_class.request(:get, 'https://api.example.com/cb')

      expect(stub.call_count).to eq(2)
      expect(stub.called?).to be(true)
    end

    it 'can produce different responses based on request data' do
      described_class.stub(:post, 'https://api.example.com/check')
                     .to_return do |request|
        if request.body == 'valid'
          { status: 200, body: 'accepted' }
        else
          { status: 422, body: 'rejected' }
        end
      end

      r1 = described_class.request(:post, 'https://api.example.com/check', body: 'valid')
      r2 = described_class.request(:post, 'https://api.example.com/check', body: 'invalid')

      expect(r1.status).to eq(200)
      expect(r1.body).to eq('accepted')
      expect(r2.status).to eq(422)
      expect(r2.body).to eq('rejected')
    end
  end

  describe Philiprehberger::HttpMock::Request do
    it 'stores method, url, headers, and body' do
      req = described_class.new(method: :post, url: 'http://example.com', body: 'data', headers: { 'X' => '1' })
      expect(req.method).to eq(:post)
      expect(req.url).to eq('http://example.com')
      expect(req.body).to eq('data')
      expect(req.headers).to eq({ 'X' => '1' })
    end

    it 'defaults body to nil and headers to empty hash' do
      req = described_class.new(method: :get, url: 'http://example.com')
      expect(req.body).to be_nil
      expect(req.headers).to eq({})
    end
  end

  describe Philiprehberger::HttpMock::Response do
    it 'defaults to 200 status with empty body and headers' do
      resp = described_class.new
      expect(resp.status).to eq(200)
      expect(resp.body).to eq('')
      expect(resp.headers).to eq({})
    end

    it 'accepts custom status, body, and headers' do
      resp = described_class.new(status: 404, body: 'not found', headers: { 'X' => 'y' })
      expect(resp.status).to eq(404)
      expect(resp.body).to eq('not found')
      expect(resp.headers).to eq({ 'X' => 'y' })
    end
  end
end
