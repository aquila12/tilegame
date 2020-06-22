# Copyright 2020 Nick Moriarty
#
# This file is provided under the term of the Eclipse Public License, the full
# text of which can be found in EPL-2.0.txt in the licenses directory of this
# repository.

class Profiler
  def self.metaprofiler
    @metaprofiler ||= Profiler.new("Profile report", 60)
  end

  def initialize(label, samples, format = '%0.1f')
    @label = label
    @samples = samples
    f = format
    @format = "#{@label}: last #{f}ms / avg #{f}ms / min #{f}ms / max #{f}ms /" +
              " jitter #{f}ms over %d samples"
    @ticktimes = []
    @total = 0
    @sum_squares = 0
    @last = nil
  end

  def now
    Time.now
  end

  def _pump(i,o)
    @total += i - o
    @sum_squares += i * i - o * o
  end

  def record(result_s)
    value = result_s*1000
    @ticktimes << value
    _pump(value, @ticktimes.length > @samples ? @ticktimes.shift : 0)
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

    @total / @ticktimes.count
  end

  def min_time
    @ticktimes.min
  end

  def max_time
    @ticktimes.max
  end

  def timing_jitter
    n = @ticktimes.count
    return 0 if n < 2

    variance = (@sum_squares - @total * @total / n) / (n - 1)
    variance ** 0.5
  end

  def report
    self.class.metaprofiler.profile {
      return "#{@label}: No data" if @ticktimes.empty?

      @format % [last_time, avg_time, min_time, max_time, timing_jitter, @ticktimes.count]
    }
  end
end
