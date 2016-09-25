require "ostruct"

RSpec.describe AwsAsCode::Task::Base do
  describe "#logger" do
    let(:config) { OpenStruct.new }
    let(:instance) { described_class.new config }
    subject { instance.logger }
    it { should be_kind_of Logger }
  end
end
