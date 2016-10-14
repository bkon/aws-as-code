Given(/^I have a cfndsl template named "(.*)" in my input dir:$/) do |filename, contents|
  path = File.join FeatureContext.instance.ruby_dir, filename
  File.open(path, "w") do |f|
    f.write contents
  end
end

Given(/^I have default configuration files in my config dir$/) do
  path = File.join FeatureContext.instance.config_dir, "settings.yml"
  File.open(path, "w") do |f|
    f.write <<YML
YML
  end

  path = File.join FeatureContext.instance.config_dir, "parameters.yml"
  File.open(path, "w") do |f|
    f.write <<YML
param:

YML
  end
end
