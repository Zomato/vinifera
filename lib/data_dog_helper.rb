# Data Dog Metrics Helper
module DataDogHelper
  PREFIX = 'vinifera_'.freeze

  class << self
    def gauge_key(key, value)
      $statsd.gauge(PREFIX + key, value)
    end

    def increment_key(key)
      $statsd.increment(PREFIX + key)
    end

    def decrement_key(key)
      $statsd.decrement(PREFIX + key)
    end
  end

end