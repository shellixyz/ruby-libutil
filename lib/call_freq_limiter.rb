
class CallFreqLimiter

  def initialize min_period
    @min_period = min_period
  end

  def enough_time_elapsed?
    last_call_time.nil? or Time.now - last_call_time > min_period
  end

  def call method = nil, *args
    if enough_time_elapsed?
      @last_call_time = Time.now
      block_given? ? yield : method.call(*args)
    end
  end

  def reset
    @last_call_time = nil
  end

  attr_reader :min_period, :last_call_time

end
