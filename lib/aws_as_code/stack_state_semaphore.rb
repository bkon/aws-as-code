require "term/ansicolor"

module AwsAsCode
  class StackStateSemaphore
    include Term::ANSIColor

    def initialize(logger:)
      @logger = logger
    end

    def wait(stack)
      wait_for_stack_availability stack
      yield
      wait_for_stack_availability stack
    end

    def wait_for_stack_availability(stack)
      # Note that stack can have old state cached, hence explicit
      # .reload here
      stack.reload.wait_until(max_attempts: 360, delay: 10) do |s|
        if in_progress? s
          log_waiting s
          false
        else
          log_proceeding s
          true
        end
      end
    end

    private

    attr_reader :logger

    def log_waiting(stack)
      message = format(
        "Stack %s is in %s state, waiting...",
        white(stack.name),
        white(stack.stack_status)
      )

      logger.info message
    end

    def log_proceeding(stack)
      message = format(
        "Stack %s is in %s state, proceeding",
        white(stack.name),
        white(stack.stack_status)
      )

      logger.info message
    end

    def in_progress?(stack)
      stack.stack_status =~ /IN_PROGRESS/
    end
  end
end
