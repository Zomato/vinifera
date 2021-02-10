class CodeScanThrottler < BaseThrottler
  PRESSURE_THRESHOLD = 5
  CONCURRENCY_FACTOR = {throttled: 20, normal: 50}.freeze
  THRESHOLD_FACTOR = {throttled: 20, normal: 50}.freeze
  THRESHOLD_PERIOD = 30.minute
  IDENTIFIER = 'code_scan'.freeze


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
