Then(/^I should have a CloudFormation template named "(.*)" in the output dir:$/) do |filename, expected_contents|
  path = File.join FeatureContext.instance.json_dir, filename
  expect(File.exist?(path)).to be_truthy

  actual_contents = File.read path

  expected_json = JSON.parse expected_contents
  actual_json = JSON.parse actual_contents
  expect(actual_json).to eq expected_json
end
