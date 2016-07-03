Given(/^I have a cfndsl template named "(.*)" in my input dir:$/) do |filename, contents|
  path = File.join FeatureContext.instance.ruby_dir, filename
  File.open(path, "w") do |f|
    f.write contents
  end
end
