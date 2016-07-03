require "logger"

RSpec.describe AwsAsCode::StackStateSemaphore do
  let(:logger) do
    l = Logger.new(STDOUT)
    # Prevent anything from being actually logged, as UNKNOWN is the
    # highest level
    l.level = Logger::Severity::UNKNOWN + 1
    l
  end

  let(:instance) do
    described_class.new logger: logger
  end

  let(:stack) do
    double "STACK",
           name: "master",
           stack_status: "CREATE_COMPLETE"
  end

  describe "#wait" do
    before do
      allow(instance).to receive(:wait_for_stack_availability)
    end

    it "waits before and after passing control to the block" do
      expect { |b| instance.wait stack, &b }.to yield_control
    end

    it "waits before and after passing control to the block" do
      allow(instance)
        .to receive(:wait_for_stack_availability)

      instance.wait stack do
        expect(instance)
          .to have_received(:wait_for_stack_availability)
          .with(stack)
          .once
      end

      expect(instance)
        .to have_received(:wait_for_stack_availability)
        .with(stack)
        .twice
    end
  end

  describe "#wait_for_stack_availability" do
    subject(:action) { instance.wait_for_stack_availability stack }

    let(:stack_in_progress) do
      double "STACK IN PROGRESS",
             name: "master",
             stack_status: "CREATE_IN_PROGRESS"
    end

    let(:stack_completed) do
      double "STACK COMPLETED",
             name: "master",
             stack_status: "CREATE_COMPLETE"
    end

    context "when stack is in progress" do
      before do
        allow(stack)
          .to receive(:wait_until)
          .and_yield(stack_in_progress)
      end

      it "logs waiting message" do
        expect(logger).to receive(:info).with(/waiting/)
        action
      end
    end

    context "when stack is completed" do
      before do
        allow(stack)
          .to receive(:wait_until)
          .and_yield(stack_completed)
      end

      it "logs completed message" do
        expect(logger).to receive(:info).with(/proceeding/)
        action
      end
    end
  end
end
