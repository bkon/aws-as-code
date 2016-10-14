require "singleton"
require "tmpdir"

# Global context for all integration tests.
# Includes:
# - temporary directories
class FeatureContext
  include Singleton

  attr_reader :ruby_dir
  attr_reader :json_dir
  attr_reader :config_dir

  def initialize
    reset
  end

  def reset
    dispose

    @ruby_dir = Dir.mktmpdir
    @json_dir = Dir.mktmpdir
    @config_dir = Dir.mktmpdir
  end

  def dispose
    dispose_of_ruby_dir
    dispose_of_json_dir
    dispose_of_config_dir
  end

  private

  def dispose_of_ruby_dir
    return unless @ruby_dir
    FileUtils.remove_entry_secure @ruby_dir
    @ruby_dir = nil
  end

  def dispose_of_json_dir
    return unless @json_dir
    FileUtils.remove_entry_secure @json_dir
    @json_dir = nil
  end

  def dispose_of_config_dir
    return unless @config_dir
    FileUtils.remove_entry_secure @config_dir
    @config_dir = nil
  end
end

Before do
  FeatureContext.instance.reset
end

After do
  FeatureContext.instance.dispose
end
