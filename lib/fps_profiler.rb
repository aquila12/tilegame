class FpsProfiler

  FORMAT = '%0.1f'
  @ticktimes = []

  def self.tick
    now = Time.now
    @ticktimes << (now - @last)*1000 if @last
    @ticktimes.shift if @ticktimes.length > 600
    @last = now
  end

  def self.last_time
    @ticktimes.last
  end

  def self.avg_time
    return '...' if @ticktimes.empty?
    total = 0
    @ticktimes.each { |t| total += t }
    total / @ticktimes.count
  end

  def self.min_time
    @ticktimes.min || '...'
  end

  def self.max_time
    @ticktimes.max || '...'
  end

  def self.jitter90
    return '...' if @ticktimes.empty?

    pc10 = (@ticktimes.length / 10).floor
    sorted = @ticktimes.sort
    sorted[-pc10] - sorted[pc10]
  end

  def self.report
    last, avg, min, max, jitter = [last_time, avg_time, min_time, max_time, jitter90].map do |m|
      String === m ? m : FORMAT % m.to_f
    end

    "last #{last}ms / avg #{avg}ms / min #{min}ms / max #{max}ms / jitter #{jitter}ms (over #{@ticktimes.count} frames)"
  end
end
