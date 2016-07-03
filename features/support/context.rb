require "singleton"
require "tmpdir"

# Global context for all integration tests.
# Includes:
# - temporary directories
class FeatureContext
  include Singleton

  attr_reader :input_dir
  attr_reader :output_dir

  def initialize
    reset
  end

  def reset
    dispose

    @input_dir = Dir.mktmpdir
    @output_dir = Dir.mktmpdir
  end

  def dispose
    dispose_of_input_dir
    dispose_of_output_dir
  end

  private

  def dispose_of_input_dir
    return unless @input_dir
    FileUtils.remove_entry_secure @input_dir
    @input_dir = nil
  end

  def dispose_of_output_dir
    return unless @output_dir
    FileUtils.remove_entry_secure @output_dir
    @output_dir = nil
  end
end

Before do
  FeatureContext.instance.reset
end

After do
  FeatureContext.instance.dispose
end
