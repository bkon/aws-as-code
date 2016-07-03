require "shellwords"

When(/^I execute the compilation command in the shell$/) do
  ruby_dir = Shellwords.escape FeatureContext.instance.ruby_dir
  json_dir = Shellwords.escape FeatureContext.instance.json_dir
  command = <<EOF
exe/aws-as-code compile \
  --ruby-dir=#{ruby_dir} \
  --json-dir=#{json_dir} \
  --bucket=aws-as-code-test-bucket \
  --template=environment \
  --stack=test
EOF
  expect(system(command)).to be_truthy
end
