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

    # Raised by stubs configured with to_timeout
    class TimeoutError < Error; end

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

      # Get the most recently recorded request
      #
      # @return [Request, nil] the last recorded request or nil
      def last_request
        registry.requests.last
      end

      # Get all recorded requests matching a method and URL
      #
      # The method comparison normalizes case (`:GET` matches `:get`). The URL
      # comparison is exact against the recorded `request.url` value, so it
      # mirrors how the stub registry stores incoming requests. Returns an
      # empty Array when no requests match.
      #
      # @param method [Symbol, String] the HTTP method to filter on
      # @param url [String] the URL to filter on
      # @return [Array<Request>] matching requests in recording order
      def requests_for(method, url)
        target_method = method.to_s.downcase.to_sym
        registry.requests.select do |req|
          req.method.to_s.downcase.to_sym == target_method && req.url == url
        end
      end

      # Shorthand for stub(:get, url)
      def stub_get(url) = stub(:get, url)

      # Shorthand for stub(:post, url)
      def stub_post(url) = stub(:post, url)

      # Shorthand for stub(:put, url)
      def stub_put(url) = stub(:put, url)

      # Shorthand for stub(:patch, url)
      def stub_patch(url) = stub(:patch, url)

      # Shorthand for stub(:delete, url)
      def stub_delete(url) = stub(:delete, url)

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
