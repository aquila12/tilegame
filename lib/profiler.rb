class Profiler
  def initialize(label, samples, jitter_percentile, format = '%0.1f')
    @label = label
    @samples = samples
    @percentile = jitter_percentile / 100
    f = format
    @format = "#{@label}: last #{f}ms / avg #{f}ms / min #{f}ms / max #{f}ms / jitter #{f}ms (over %d frames)"
    @ticktimes = []
    @last = nil
  end

  def now
    Time.now
  end

  def record(result_s)
    @ticktimes << result_s*1000
    @ticktimes.shift if @ticktimes.length > @samples
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
    @ticktimes.last
  end

  def avg_time
    return if @ticktimes.empty?
    total = 0
    @ticktimes.each { |t| total += t }
    total / @ticktimes.count
  end

  def min_time
    @ticktimes.min
  end

  def max_time
    @ticktimes.max
  end

  def timing_jitter
    return '...' if @ticktimes.empty?

    pc = (@ticktimes.count * @percentile).floor
    sorted = @ticktimes.sort
    sorted[-pc] - sorted[pc]
  end

  def report
    return "#{@label}: No data" if @ticktimes.empty?

    @format % [last_time, avg_time, min_time, max_time, timing_jitter, @ticktimes.count]
  end
end
