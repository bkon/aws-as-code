require "cfndsl"
require "yaml"
require "fileutils"

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

      def load_params
        param_filename = File.join config.config_dir, "parameters.yml"
        return [] unless File.exist? param_filename
        YAML.load_file(param_filename).to_a
      end

      def def_params
        pairs = load_params

        CfnDsl::JSONable.send :define_method, :params do |env = nil|
          pairs.reject do |pair|
            data = pair.last
            services = data["_ext"]["services"]

            !env.nil? &&
              !services.nil? &&
              !services.include?(env)
          end.to_h
        end
      end

      def def_template_url
        c = config
        CfnDsl::JSONable.send :define_method, :template_url do |name|
          prefix = "#{c.stack}/#{c.version}"
          "https://s3.amazonaws.com/#{c.bucket}/#{prefix}/#{name}.json"
        end
      end

      def load_settings
        filename = File.join config.config_dir, "settings.yml"
        YAML.load_file(filename)
      end

      def def_settings
        data = load_settings
        c = config
        CfnDsl::JSONable.send :define_method, :setting do |name|
          data[name][c.stack] || data[name]["_default"]
        end
      end

      def compile_single_file(filename)
        def_params
        def_settings
        def_template_url

        cfn = binding.eval(File.read(filename), filename)
        save_output cfn, filename
      end

      def save_output(cfn, filename)
        dest = File.join config.json_dir,
                         output_pathname(filename)

        dirname = File.dirname(dest)
        FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

        File.open(dest, "w") { |f| f.write cfn.to_json }
      end

      def output_pathname(filename)
        Pathname
          .new(filename)
          .relative_path_from(Pathname.new(config.ruby_dir))
          .sub_ext(".json")
          .to_s
      end

      def input_files
        Dir.glob(File.join(config.ruby_dir, "**/*.rb"))
      end
    end
  end
end
