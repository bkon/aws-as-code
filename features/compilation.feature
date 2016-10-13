Feature: Template compilation

  Scenario: compiling cfndsl templates to CloudFormation JSON

    Given I have a cfndsl template named "test.rb" in my input dir:
    """
CloudFormation do
  Parameter "SampleInput" do
    String
    Default "foo"
    Description "This is a sample parameter"
  end
end
    """
    And I have default configuration files in my config dir

    When I execute the compilation command in the shell
    Then I should have a CloudFormation template named "test.json" in the output dir:
    """
{
  "AWSTemplateFormatVersion": "2010-09-09",
  "Parameters": {
    "SampleInput": {
      "Type": "String",
      "Default": "foo",
      "Description": "This is a sample parameter"
    }
  }
}
    """
