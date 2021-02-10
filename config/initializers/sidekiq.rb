require 'sidekiq/throttled'
Sidekiq::Throttled.setup!

redis_url = ENV.fetch('SIDEKIQ_REDIS_URL') { 'redis://localhost:6379/2' }

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url, network_timeout: 5 }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url, network_timeout: 5 }
end

Sidekiq::Throttled::Registry.add(:code_scanner_throttler, CodeScanThrottler.new.throttle_config)