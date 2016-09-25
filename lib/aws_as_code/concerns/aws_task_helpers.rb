module AwsAsCode
  module Concerns
    module AwsTaskHelpers
      private

      def semaphore
        StackStateSemaphore.new logger: logger
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
        bucket.object "#{config.stack}/#{config.template}.json"
      end
    end
  end
end
