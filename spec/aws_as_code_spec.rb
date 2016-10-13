RSpec.describe AwsAsCode do
  it "has a version number" do
    expect(AwsAsCode::VERSION).not_to be nil
  end
end

RSpec.describe CfnDsl::JSONable do
  let(:instance) { described_class.new }

  let(:params) do
    YAML.load(
      <<YAML
Param1:
  Type: String
  Default: test
  _ext:
    env: ENV1
    secure: true
Param2:
  Type: Number
  Default: test
  _ext:
    env: ENV2
    secure: true
    services:
      - s1
      - s2
Param3:
  Type: CommaDelimitedList
  Default: test
  _ext:
    env: ENV3
    secure: true
    services:
      - s1
Param4:
  Type: String
  Default: test
  _ext:
    env: ENV4
    secure: true
    services:
      - s2
YAML
    )
  end

  before do
    allow_any_instance_of(CfnDsl::JSONable)
      .to receive(:params)
      .and_return params
  end

  describe "#inputs" do
    subject do
      JSON.parse(
        CloudFormation do
          inputs
        end.to_json
      )
    end

    context "when parameter declaration contains an invalid type" do
      let(:params) do
        YAML.load(
          <<YAML
Param1:
  Type: BadParameterType
  Default: test
  _ext:
    env: ENV1
    secure: true
YAML
        )
      end

      it "raises an exception" do
        expect { subject }.to raise_error ArgumentError
      end
    end

    it "generates input declarations" do
      expected = JSON.parse(
        <<JSON
{
  "Parameters": {
    "Param1": {
      "Type": "String",
      "Default": "test"
    },
    "Param2": {
      "Type": "Number",
      "Default": "test"
    },
    "Param3": {
      "Type": "CommaDelimitedList",
      "Default": "test"
    },
    "Param4": {
      "Type": "String",
      "Default": "test"
    }
  }
}
JSON
      )
      expect(subject).to match hash_including expected
    end
  end

  describe "#env_passthrough" do
    subject { CfnDsl::JSONable.new.env_passthrough }

    it "returns a list of matching parameters" do
      expect(subject)
        .to match Hash[
                    "Param1" => anything,
                    "Param2" => anything,
                    "Param3" => anything,
                    "Param4" => anything
                  ]
    end
  end

  describe "#env_ebs_options" do
    subject { CfnDsl::JSONable.new.env_ebs_options }

    it "generates a list of ElasticBeanstalk options" do
      expect(subject)
        .to match [
              {
                Namespace: "aws:elasticbeanstalk:application:environment",
                OptionName: "ENV1",
                Value: anything
              },
              {
                Namespace: "aws:elasticbeanstalk:application:environment",
                OptionName: "ENV2",
                Value: anything
              },
              {
                Namespace: "aws:elasticbeanstalk:application:environment",
                OptionName: "ENV3",
                Value: anything
              },
              {
                Namespace: "aws:elasticbeanstalk:application:environment",
                OptionName: "ENV4",
                Value: anything
              }
            ]
    end
  end
end
