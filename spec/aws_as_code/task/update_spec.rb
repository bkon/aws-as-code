require "ostruct"

RSpec.describe AwsAsCode::Task::Update do
  let(:config) do
    OpenStruct.new stack: "test-stack",
                   stack_params: {
                     removed: "",
                     new: "NEW",
                     updated: "UPDATED"
                   }
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

  let(:status) { "UPDATE_SUCCESS" }

  let(:stack) do
    obj = double "Stack",
                 parameters: [
                   OpenStruct.new(parameter_key: "removed",
                                  parameter_value: "1"),
                   OpenStruct.new(parameter_key: "updated",
                                  parameter_value: "2"),
                   OpenStruct.new(parameter_key: "ignored",
                                  parameter_value: "3")
                 ],
                 stack_status: status
    allow(obj).to receive(:reload).and_return obj
    obj
  end

  describe "#execute" do
    subject(:action) { instance.execute }

    let(:expected_parameters) do
      [
        { parameter_key: "ignored", use_previous_value: true },
        { parameter_key: "updated", parameter_value: "UPDATED" },
        { parameter_key: "new", parameter_value: "NEW" }
      ]
    end

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

    it "passes a correct list of parameters" do
      expect(cf)
        .to receive(:update_stack)
        .with(hash_including parameters: match_array(expected_parameters))
      action
    end

    it "returns 0 status (shell success)" do
      expect(action).to eq 0
    end

    context "when operation fails" do
      let(:status) { "UPDATE_ROLLBACK_COMPLETE" }

      it "returns 1 status (shell failure)" do
        expect(action).to eq 1
      end
    end
  end
end
