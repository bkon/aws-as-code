# frozen_string_literal: true
module AwsAsCode
  module Task
    class Update < Base
      include AwsAsCode::Concerns::AwsTaskHelpers

      def execute
        semaphore.wait(stack) do
          cloud_formation
            .update_stack stack_name: config.stack,
                          template_url: template_object.public_url,
                          parameters: []
        end
      end
    end
  end
end
