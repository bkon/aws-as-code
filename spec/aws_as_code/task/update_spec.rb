require "ostruct"

RSpec.describe AwsAsCode::Task::Update do
  let(:config) do
    OpenStruct.new stack: "test-stack"
  end

  let(:instance) do
    described_class.new config
  end

  let(:cf) do
    double "CF", update_stack: nil
  end

  let(:semaphore) do
    double "Semaphore"
  end

  let(:template_object) do
    double "Template", public_url: nil
  end

  let(:stack) do
    double "Stack"
  end

  describe "#execute" do
    subject(:action) { instance.execute }

    before do
      allow(instance).to receive(:cloud_formation).and_return cf
      allow(instance).to receive(:semaphore).and_return semaphore
      allow(instance).to receive(:template_object).and_return template_object
      allow(instance).to receive(:stack).and_return stack
      allow(semaphore).to receive(:wait).and_yield
    end

    it "attempts to update the stack" do
      expect(cf).to receive :update_stack
      action
    end

    it "waits for stack status to allow modifications" do
      expect(semaphore).to receive(:wait).with(stack)
      action
    end
  end
end
