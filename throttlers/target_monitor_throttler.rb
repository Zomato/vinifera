class TargetMonitorThrottler < BaseThrottler
  PRESSURE_THRESHOLD = 10
  CONCURRENCY_FACTOR = {throttled: 20, normal: 100}.freeze
  THRESHOLD_FACTOR = {throttled: 2500, normal: 5000}.freeze # Change these values are per your load and expected capacity
  THRESHOLD_PERIOD = 10.minutes
  IDENTIFIER = 'target_monitor'.freeze

  def initialize
    super(IDENTIFIER,prepare_opts)
  end

  private

  def prepare_opts
    {
      identifier: IDENTIFIER,
      concurrency_factor: BaseThrottler::Factor.new(CONCURRENCY_FACTOR),
      threshold_factor: BaseThrottler::Factor.new(THRESHOLD_FACTOR),
      limits: BaseThrottler::Limits.new(period: THRESHOLD_PERIOD, pressure_threshold: PRESSURE_THRESHOLD)
    }
  end
end
