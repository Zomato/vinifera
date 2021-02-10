class ModelMetrics
  include Singleton
  def push_stats
    return unless Rails.env.production?

    continuous_stats = {
        target_count: Target.count,
        target_monitor_count: TargetMonitor.count,
        report_count: Report.count,
        target_revision_count: TargetRevision.count,
        target_github_repo_count: Target.github.repo.count,
        target_github_gist_count: Target.github.gist.count,
        target_github_user_count: Target.github.user.count
    }
    $statsd.batch do
      [continuous_stats].each do |data|
        push_data_to_statsd(data, :count)
      end
    end
  end

  private

  def push_data_to_statsd(data, push_type)
    key_prefix = "vinifera_model_stats_#{Rails.env}"
    data.each do |event, value|
      $statsd.send(push_type, "#{key_prefix}_#{event}", value)
    end
  end
end