# frozen_string_literal: true
require "aws_as_code/version"
require "aws_as_code/stack_state_semaphore"
require "aws_as_code/concerns/aws_task_helpers"
require "aws_as_code/dsl/cache_instances"
require "aws_as_code/dsl/ec2_instances"
require "aws_as_code/dsl/rds_instances"
require "aws_as_code/task/base"
require "aws_as_code/task/compile"
require "aws_as_code/task/upload"
require "aws_as_code/task/create"
require "aws_as_code/task/update"

module CfnDsl
  class JSONable
    def parameter_type(type)
      case type
      when "String" then String()
      when "Number" then Number()
      when "CommaDelimitedList" then CommaDelimitedList()
      else raise ArgumentError, "Unknown parameter type #{type}"
      end
    end

    def inputs(env = nil)
      params(env).each do |name, data|
        Parameter name do
          parameter_type data["Type"]

          Default data["Default"] unless data["Default"].nil?
          Description data["Description"] unless data["Description"].nil?
        end
      end
    end

    def env_passthrough(env = nil)
      Hash[
        params(env).to_a.map do |pair|
          k = pair.first
          [k, Ref(k)]
        end
      ]
    end

    def env_ebs_options(env = nil)
      params(env).map do |name, data|
        {
          Namespace: "aws:elasticbeanstalk:application:environment",
          OptionName: data["_ext"]["env"],
          Value: Ref(name)
        }
      end
    end
  end
end
