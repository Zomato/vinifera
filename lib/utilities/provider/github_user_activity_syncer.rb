class GithubUserActivitySyncer

  def initialize
    @github = Github.new
    @commit_event_processor = GithubService::PublicCommitProcessor.new
  end

  def sync_activity(target, last_run = nil)
    username = target.slug
    last_run = Time.zone.parse(last_run) if last_run
    event_opts = {last_id_processed: target.meta_data.try(:[], 'last_event_id_processed'), filter_date: last_run}
    events = @github.user_public_commits(username, event_opts)
    @commit_event_processor.process(events, target)
    target.add_meta_data!({last_event_id_processed: events.first.id}) if events.present?
  end
end