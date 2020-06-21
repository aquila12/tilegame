class Profiler
  FORMAT = '%0.1f'

  def initialize(label, samples, jitter_percentile)
    @label = label
    @ticktimes = []
    @percentile = jitter_percentile / 100
    @last = nil
  end

  def now
    Time.now
  end

  def record(result_us)
    @ticktimes << result_us
    @ticktimes.shift if @ticktimes.length > 600
  end

  def profile
    start = now
    r = yield
    record(now - start)
    r
  end

  def profile_between_calls
    t = now
    record(t - @last) if @last
    @last = t
  end

  def last_time
    @ticktimes.last || '...'
  end

  def avg_time
    return '...' if @ticktimes.empty?
    total = 0
    @ticktimes.each { |t| total += t }
    total / @ticktimes.count
  end

  def min_time
    @ticktimes.min || '...'
  end

  def max_time
    @ticktimes.max || '...'
  end

  def timing_jitter
    return '...' if @ticktimes.empty?

    pc = (@ticktimes.count * @percentile).floor
    sorted = @ticktimes.sort
    sorted[-pc] - sorted[pc]
  end

  def report
    timing_parameters = [last_time, avg_time, min_time, max_time, timing_jitter]
    last, avg, min, max, jitter = timing_parameters.map do |m|
      String === m ? m : FORMAT % (m*1000).to_f
    end

    "#{@label}: last #{last}ms / avg #{avg}ms / min #{min}ms / max #{max}ms / jitter #{jitter}ms (over #{@ticktimes.count} frames)"
  end
end
