# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::HttpMock do
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
  end

  describe 'stub with regex URL' do
    it 'matches URLs by regex' do
      described_class.stub(:get, %r{/users/\d+}).to_return(status: 200, body: '{"id":1}')

      response = described_class.request(:get, 'https://api.example.com/users/42')
      expect(response.status).to eq(200)
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
end
