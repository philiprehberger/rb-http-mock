# frozen_string_literal: true

module Philiprehberger
  module HttpMock
    # Represents a stubbed HTTP response
    class Response
      # @return [Integer] the HTTP status code
      attr_reader :status

      # @return [String] the response body
      attr_reader :body

      # @return [Hash] the response headers
      attr_reader :headers

      # @param status [Integer] the HTTP status code
      # @param body [String] the response body
      # @param headers [Hash] the response headers
      def initialize(status: 200, body: '', headers: {})
        @status = status
        @body = body
        @headers = headers
      end
    end
  end
end
