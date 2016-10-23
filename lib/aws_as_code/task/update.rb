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
                          parameters: parameters
        end
        exit_code_for_stack_state stack.reload
      end

      private

      def parameters
        existing_parameters + overridden_parameters
      end

      def existing_parameters
        keys = stack.parameters.map(&:parameter_key)
        (keys - removed_keys - overridden_keys).map do |key|
          {
            parameter_key: key,
            use_previous_value: true
          }
        end
      end

      def removed_keys
        config.stack_params.to_a.map do |pair|
          k, v = pair
          v.empty? ? k.to_s : nil
        end.compact
      end

      def overridden_keys
        overridden_parameters.map { |p| p[:parameter_key] }
      end

      def overridden_parameters
        config.stack_params.to_a.map do |pair|
          k, v = pair

          next nil if v.empty?

          {
            parameter_key: k.to_s,
            parameter_value: v
          }
        end.compact
      end
    end
  end
end
