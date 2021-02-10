namespace :every_minute do
  task send_sidekiq_stats: :environment do |_, _args|
    SidekiqMetrics.instance.push_stats
  end
end