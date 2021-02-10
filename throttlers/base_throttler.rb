class BaseThrottler

  DEFAULT_THRESHOLD_PERIOD = 1.hour
  THROTTLE_INDICATOR_KEY = '_throttle_indicator_key'.freeze
  THROTTLE_REPORTED_KEY = '_throttled_reported_key'.freeze
  LOCK_KEY = '_throttle_lock_key_'.freeze
  THROTTLE_REPORT_LOCK_KEY = '_throttle_report_lock_key'.freeze

  Factor = Struct.new(:throttled, :normal, keyword_init: true)
  Limits = Struct.new(:pressure_threshold, :period, keyword_init: true)

  def initialize(name, opts)
    @identifier = name
    @red_lock = Redlock::Client.new
    _init_(opts)
  end

  def throttle_config
    {
      concurrency: { limit: ->(_, *_args) { throttled_factor(@concurrency_factor) } },
      threshold: { limit: ->(_, *_args) { throttled_factor(@threshold_factor) }, period: @limits.period },
      observer: lambda do |strategy, *args|
        @red_lock.lock(@identifier + THROTTLE_REPORT_LOCK_KEY + strategy.to_s, 1.seconds.in_milliseconds) do |locked|
          return unless locked

          return if Rails.cache.read(@identifier + THROTTLE_REPORTED_KEY + strategy.to_s)


          Rails.cache.write(@identifier + THROTTLE_REPORTED_KEY + strategy.to_s, true, expires_in: @limits.period)
          message = "Throttling activated for #{@identifier}. Strategy: #{strategy} Args: #{args}"
          SlackNotifier.new.notify(message, SlackNotifier::CHANNELS[:ERROR])
        end
      end
    }
  end

  def throttle
    @red_lock.lock(cache_key(LOCK_KEY), 1.seconds.in_milliseconds) do |locked|
      return unless locked

      return if throttled?

      Rails.cache.increment(cache_key(THROTTLE_INDICATOR_KEY), 1, expires_in: @limits.period)
    end
  end

  def reset!
    Rails.cache.delete(cache_key(THROTTLE_INDICATOR_KEY))

  end

  private

  def throttled?
    Rails.cache.read(cache_key(THROTTLE_INDICATOR_KEY), raw: true).to_i > @limits.pressure_threshold
  end

  def throttled_factor(factor)
    throttled? ? factor.throttled : factor.normal
  end

  def cache_key(template_key)
    "#{@identifier}_#{template_key}"
  end

  def _init_(opts)
    @concurrency_factor = opts[:concurrency_factor]
    @threshold_factor = opts[:threshold_factor]
    @limits = opts[:limits]
  end
end
