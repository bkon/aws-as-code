require "ostruct"

RSpec.describe AwsAsCode::Task::Create do
  let(:config) do
    OpenStruct.new stack: "test-stack",
                   template: "env",
                   version: "VERSION",
                   stack_params: {
                     DBPassword: "XXX"
                   }
  end

  let(:instance) do
    described_class.new config
  end

  let(:cf) do
    double "CF", create_stack: nil
  end

  let(:semaphore) do
    double "Semaphore", wait_for_stack_availability: nil
  end

  let(:template_object) do
    double "Template", public_url: nil
  end

  let(:status) { "CREATE_SUCCESS" }

  let(:stack) do
    obj = double "Stack",
                 stack_status: status
    allow(obj).to receive(:reload).and_return obj
    obj
  end

  describe "#execute" do
    subject(:action) { instance.execute }

    before do
      allow(instance).to receive(:cloud_formation).and_return cf
      allow(instance).to receive(:semaphore).and_return semaphore
      allow(instance).to receive(:template_object).and_return template_object
      allow(instance).to receive(:stack).and_return stack
    end

    it "attempts to create the stack" do
      expect(cf)
        .to receive(:create_stack)
        .with(stack_name: "test-stack",
              template_url: anything,
              parameters: [
                {
                  parameter_key: "DBPassword",
                  parameter_value: "XXX"
                }
              ])
      action
    end

    it "waits for stack to become available" do
      expect(semaphore).to receive :wait_for_stack_availability
      action
    end

    it "returns 0 status (shell success)" do
      expect(action).to eq 0
    end

    context "when operation fails" do
      let(:status) { "CREATE_FAILED" }

      it "returns 1 status (shell failure)" do
        expect(action).to eq 1
      end
    end
  end

  describe "#semaphore" do
    subject { instance.send :semaphore }
    it { should be_kind_of AwsAsCode::StackStateSemaphore }
  end

  describe "#cloud_formation" do
    subject { instance.send :cloud_formation }

    it "creates new CF client" do
      expect(Aws::CloudFormation::Client).to receive(:new)
      subject
    end
  end

  describe "#s3" do
    subject { instance.send :s3 }

    it "creates new S3 client" do
      expect(Aws::S3::Resource).to receive(:new)
      subject
    end
  end

  describe "#stack" do
    subject { instance.send :stack }

    it "creates new Stack object" do
      expect(Aws::CloudFormation::Stack).to receive(:new)
      subject
    end
  end

  describe "#template_object" do
    subject { instance.send :template_object }

    let(:bucket) { double("Bucket") }

    before do
      allow(instance)
        .to receive_message_chain(:s3, :bucket)
        .and_return bucket
    end

    it "uses stack and template name to generate the object key" do
      expect(bucket).to receive(:object).with("test-stack/VERSION/env.json")
      subject
    end
  end
end
