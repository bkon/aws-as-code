require "aws-sdk"
require "pathname"

# frozen_string_literal: true
module AwsAsCode
  module Task
    class Upload < Base
      def execute
        input_files.each { |filename| upload_single_file filename }
      end

      private

      def upload_single_file(filename)
        bucket
          .object(s3_object_name(filename))
          .upload_file filename
      end

      def bucket
        s3 = Aws::S3::Resource.new
        s3.bucket config.bucket
      end

      def s3_object_name(filename)
        template_path = Pathname.new filename
        config_path = Pathname.new config.json_dir

        key = template_path
              .relative_path_from(config_path)
              .to_s

        [
          config.stack,
          config.version,
          key
        ].join("/")
      end

      def input_files
        Dir.glob File.join(config.json_dir, "**/*.json")
      end
    end
  end
end
