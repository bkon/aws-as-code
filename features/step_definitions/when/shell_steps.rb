require "shellwords"

When(/^I execute the compilation command in the shell$/) do
  input_dir = Shellwords.escape FeatureContext.instance.input_dir
  output_dir = Shellwords.escape FeatureContext.instance.output_dir
  command = "bin/aws-as-code compile --input-dir #{input_dir} --output-dir #{output_dir}"
  expect(system(command)).to be_truthy
end
