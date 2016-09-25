# frozen_string_literal: true
module AwsAsCode
  module Task
    class Create < Base
      include AwsAsCode::Concerns::AwsTaskHelpers

      def execute
        cloud_formation
          .create_stack stack_name: config.stack,
                        template_url: template_object.public_url,
                        parameters: []
        semaphore.wait_for_stack_availability stack
      end
    end
  end
end
