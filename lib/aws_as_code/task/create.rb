# frozen_string_literal: true
module AwsAsCode
  module Task
    class Create < Base
      include AwsAsCode::Concerns::AwsTaskHelpers

      def execute
        cloud_formation
          .create_stack stack_name: config.stack,
                        template_url: template_object.public_url,
                        parameters: parameters
        semaphore.wait_for_stack_availability stack
      end

      private

      def parameters
        config.stack_params.to_a.map do |pair|
          k, v = pair
          {
            parameter_key: k.to_s,
            parameter_value: v
          }
        end
      end
    end
  end
end
