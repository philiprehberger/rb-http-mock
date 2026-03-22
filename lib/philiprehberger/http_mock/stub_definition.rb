# frozen_string_literal: true

module Philiprehberger
  module HttpMock
    # Defines a request stub with matching criteria and response
    class StubDefinition
      # @return [Symbol] the HTTP method
      attr_reader :method

      # @return [String, Regexp] the URL pattern
      attr_reader :url

      # @return [Hash] additional matching criteria
      attr_reader :constraints

      # @return [Response, nil] the response to return
      attr_reader :response

      # @param method [Symbol] the HTTP method to match
      # @param url [String, Regexp] the URL or pattern to match
      def initialize(method, url)
        @method = method
        @url = url
        @constraints = {}
        @response = Response.new
      end

      # Set additional matching constraints
      #
      # @param body [String, Hash, nil] the expected request body
      # @param headers [Hash, nil] the expected request headers
      # @return [self]
      def with(body: nil, headers: nil)
        @constraints[:body] = body if body
        @constraints[:headers] = headers if headers
        self
      end

      # Set the response to return when this stub matches
      #
      # @param status [Integer] the HTTP status code
      # @param body [String] the response body
      # @param headers [Hash] the response headers
      # @return [self]
      def to_return(status: 200, body: '', headers: {})
        @response = Response.new(status: status, body: body, headers: headers)
        self
      end

      # Check if a request matches this stub
      #
      # @param request [Request] the request to check
      # @return [Boolean] true if the request matches
      def matches?(request)
        return false unless request.method == @method
        return false unless url_matches?(request.url)
        return false unless body_matches?(request.body)
        return false unless headers_match?(request.headers)

        true
      end

      private

      def url_matches?(request_url)
        if @url.is_a?(Regexp)
          @url.match?(request_url)
        else
          @url == request_url
        end
      end

      def body_matches?(request_body)
        return true unless @constraints.key?(:body)

        @constraints[:body] == request_body
      end

      def headers_match?(request_headers)
        return true unless @constraints.key?(:headers)

        @constraints[:headers].all? do |key, value|
          request_headers[key] == value
        end
      end
    end
  end
end
