# frozen_string_literal: true
module AwsAsCode
  # Contains shared configuration settings for all
  # tasks in the gem.
  class Config
    attr_reader :input_directory
    attr_reader :output_directory

    def initialize(input_directory: nil, output_directory: nil)
      @input_directory = input_directory || "input"
      @output_directory = output_directory || "output"
    end
  end
end
