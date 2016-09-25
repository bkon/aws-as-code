# frozen_string_literal: true
module AwsAsCode
  module Task
    class Base
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def logger
        @logger = Logger.new STDOUT
      end
    end
  end
end
