class SidekiqMetrics
  include Singleton
  def push_stats
    return unless Rails.env.production?

    sidekiq_stats = Sidekiq::Stats.new
    continuous_stats = {
        enqueued: sidekiq_stats.enqueued,
        busy: Sidekiq::Workers.new.size,
        retries: sidekiq_stats.retry_size,
        dead: sidekiq_stats.dead_size,
        workers: sidekiq_stats.workers_size
    }
    count_stats = {processed: sidekiq_stats.processed, failed: sidekiq_stats.failed}
    $statsd.batch do
      [count_stats, continuous_stats, sidekiq_stats.queues].each do |data|
        push_data_to_statsd(data, :gauge)
      end
      # Latency data
      sidekiq_stats.queues.each do |queue,_|
        latency = Sidekiq::Queue.new(queue).latency
        push_data_to_statsd({"#{queue}_latency" => latency},:gauge)
      end
    end
  end

  private

  def push_data_to_statsd(data, push_type)
    key_prefix = "vinifera_sidekiq_stats_#{Rails.env}"
    data.each do |event, value|
      $statsd.send(push_type, "#{key_prefix}_#{event}", value)
    end
  end
end