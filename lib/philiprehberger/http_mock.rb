# frozen_string_literal: true

require_relative 'http_mock/version'
require_relative 'http_mock/request'
require_relative 'http_mock/response'
require_relative 'http_mock/stub_definition'
require_relative 'http_mock/registry'

module Philiprehberger
  module HttpMock
    class Error < StandardError; end

    # Unexpected request error raised when no stub matches
    class UnmatchedRequestError < Error; end

    # Raised when verify! finds stubs that were never called
    class UnmatchedStubError < Error; end

    @registry = Registry.new

    class << self
      # Stub an HTTP request
      #
      # @param method [Symbol] the HTTP method (:get, :post, :put, :patch, :delete, :head, :options)
      # @param url [String, Regexp] the URL or pattern to match
      # @return [StubDefinition] the stub definition for chaining
      def stub(method, url)
        stub_def = StubDefinition.new(method, url)
        registry.register(stub_def)
      end

      # Simulate an HTTP request against registered stubs
      #
      # @param method [Symbol] the HTTP method
      # @param url [String] the request URL
      # @param body [String, nil] the request body
      # @param headers [Hash] the request headers
      # @return [Response] the matched stub response
      # @raise [UnmatchedRequestError] if no stub matches
      def request(method, url, body: nil, headers: {})
        req = Request.new(method: method, url: url, body: body, headers: headers)
        registry.record(req)

        matched = registry.find_stub(req)
        raise UnmatchedRequestError, "No stub matched #{method.upcase} #{url}" unless matched

        matched.response_for(req)
      end

      # Get all recorded requests
      #
      # @return [Array<Request>] the recorded requests
      def requests
        registry.requests.dup
      end

      # Verify that all registered stubs were called at least once
      #
      # @return [void]
      # @raise [UnmatchedStubError] if any stub was never called
      def verify!
        uncalled = registry.stubs.reject(&:called?)
        return if uncalled.empty?

        descriptions = uncalled.map { |s| "#{s.method.upcase} #{s.url}" }
        raise UnmatchedStubError, "The following stubs were never called: #{descriptions.join(', ')}"
      end

      # Clear all stubs and recorded requests
      #
      # @return [void]
      def reset!
        registry.reset!
      end

      # Execute a block with isolated stubs that are automatically cleaned up
      #
      # @yield the block to execute with isolated stubs
      # @return [Object] the block return value
      def scope(&block)
        previous = @registry
        @registry = Registry.new
        block.call
      ensure
        @registry = previous
      end

      private

      attr_reader :registry
    end
  end
end
