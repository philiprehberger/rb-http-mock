# frozen_string_literal: true

module Philiprehberger
  module HttpMock
    # Thread-safe registry of stub definitions and recorded requests
    class Registry
      # @return [Array<StubDefinition>] registered stubs
      attr_reader :stubs

      # @return [Array<Request>] recorded requests
      attr_reader :requests

      def initialize
        @stubs = []
        @requests = []
        @mutex = Mutex.new
      end

      # Register a new stub definition
      #
      # @param stub_def [StubDefinition] the stub to register
      # @return [StubDefinition] the registered stub
      def register(stub_def)
        @mutex.synchronize { @stubs << stub_def }
        stub_def
      end

      # Record an incoming request
      #
      # @param request [Request] the request to record
      # @return [void]
      def record(request)
        @mutex.synchronize { @requests << request }
      end

      # Find a matching stub for a request
      #
      # @param request [Request] the request to match
      # @return [StubDefinition, nil] the matching stub or nil
      def find_stub(request)
        @mutex.synchronize do
          @stubs.reverse_each.find { |s| s.matches?(request) }
        end
      end

      # Clear all stubs and recorded requests
      #
      # @return [void]
      def reset!
        @mutex.synchronize do
          @stubs.clear
          @requests.clear
        end
      end
    end
  end
end
