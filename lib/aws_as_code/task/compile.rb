require "cfndsl"

# frozen_string_literal: true
module AwsAsCode
  module Task
    # Compiles all input templates and puts
    # JSON to the output directory
    class Compile
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def execute
        input_files.each { |filename| compile_single_file filename }
      end

      private

      def compile_single_file(filename)
        output_filename = File.basename(filename, ".rb") + ".json"
        output_pathname = File.join config.output_directory, output_filename

        cfn = CfnDsl.eval_file_with_extras(
          filename,
          [],
          STDERR
        )

        File.open(output_pathname, "w") { |f| f.write cfn.to_json }
      end

      def input_files
        Dir.glob(File.join(config.input_directory, "**/*.rb"))
      end
    end
  end
end
