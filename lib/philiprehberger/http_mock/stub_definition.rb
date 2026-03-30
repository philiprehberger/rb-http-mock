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

      # @return [Integer] number of times this stub has been matched
      attr_reader :call_count

      # @param method [Symbol] the HTTP method to match
      # @param url [String, Regexp] the URL or pattern to match
      def initialize(method, url)
        @method = method
        @url = url
        @constraints = {}
        @response = Response.new
        @response_sequence = nil
        @response_callback = nil
        @call_count = 0
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
      # @yield [Request] optional block for dynamic response generation
      # @return [self]
      def to_return(status: 200, body: '', headers: {}, &block)
        if block
          @response_callback = block
          @response = nil
          @response_sequence = nil
        else
          @response = Response.new(status: status, body: body, headers: headers)
          @response_callback = nil
          @response_sequence = nil
        end
        self
      end

      # Set a sequence of responses to cycle through
      #
      # @param responses [Array<Hash>] array of response hashes with :status, :body, :headers keys
      # @return [self]
      def to_return_in_sequence(responses)
        @response_sequence = responses.map do |resp|
          Response.new(
            status: resp.fetch(:status, 200),
            body: resp.fetch(:body, ''),
            headers: resp.fetch(:headers, {})
          )
        end
        @response = nil
        @response_callback = nil
        self
      end

      # Return the response for this stub, advancing sequence if applicable
      #
      # @param request [Request] the matched request
      # @return [Response] the response to return
      def response_for(request)
        @call_count += 1

        if @response_callback
          result = @response_callback.call(request)
          Response.new(
            status: result.fetch(:status, 200),
            body: result.fetch(:body, ''),
            headers: result.fetch(:headers, {})
          )
        elsif @response_sequence
          index = [@call_count - 1, @response_sequence.length - 1].min
          @response_sequence[index]
        else
          @response
        end
      end

      # Whether this stub has been called at least once
      #
      # @return [Boolean]
      def called?
        @call_count > 0
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
