# frozen_string_literal: true

module Philiprehberger
  module HttpMock
    # Represents a recorded HTTP request
    class Request
      # @return [Symbol] the HTTP method (:get, :post, etc.)
      attr_reader :method

      # @return [String] the request URL
      attr_reader :url

      # @return [Hash] the request headers
      attr_reader :headers

      # @return [String, nil] the request body
      attr_reader :body

      # @param method [Symbol] the HTTP method
      # @param url [String] the request URL
      # @param headers [Hash] the request headers
      # @param body [String, nil] the request body
      def initialize(method:, url:, headers: {}, body: nil)
        @method = method
        @url = url
        @headers = headers
        @body = body
      end
    end
  end
end
