# TODO: Figure out how to make it work.
module CustomApeMatchers
  class ReporterMatcher
    def initialize(*expected)
      @type = expected.first
      @message = expected.last
    end

    def matches?(target)
      @target = target
      @target.reporter.should_receive(:call).with(@target, @type, @message)
    end

    def failure_message
      "expected #{@target.inspect} to report a #{@type.to_s} with #{@message.inspect}"
    end

    def negative_failure_message
      "expected #{@target.inspect} to not report a #{@type.to_s} with #{@message.inspect}"
    end
  end

  def notify(message)
    ReporterMatcher.new(:notice, message)
  end
end

def should_report(type, message)
  @validator.reporter.should_receive(:call).with(@validator, type, message)
end
