# frozen_string_literal: true

module AwsAsCode
  module Concerns
    module AwsTaskHelpers
      private

      def semaphore
        StackStateSemaphore.new logger: logger
      end

      def exit_code_for_stack_state(stack)
        state_indicates_failure?(stack) ? 1 : 0
      end

      def state_indicates_failure?(stack)
        stack.stack_status =~ /ROLLBACK/ || stack.stack_status =~ /FAILED/
      end

      def cloud_formation
        @cloud_formation ||= Aws::CloudFormation::Client.new
      end

      def s3
        @s3 ||= Aws::S3::Resource.new
      end

      def stack
        @stack ||= Aws::CloudFormation::Stack.new config.stack
      end

      def template_object
        bucket = s3.bucket config.bucket
        prefix = "#{config.stack}/#{config.version}"
        bucket.object "#{prefix}/#{config.template}.json"
      end
    end
  end
end
