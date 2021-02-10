class GithubUserGistSyncer
  def initialize
    @github = Github.new
    @transformer = TargetTransformer.new
    @service = TargetService.new
    @slack_notifier = SlackNotifier.new
  end

  def sync_gists(target)
    gh_username = target.slug
    gists = @github.user_gists(gh_username)
    transformed_gists = @transformer.transform_all(gists, Target.providers[:github], Target.target_types[:gist])
    result = @service.register(transformed_gists)
    target_ids = result.pluck('id')

    if target.meta_data.try(:[], 'gist_count').to_i != transformed_gists.count
       target.add_meta_data!({gist_count: transformed_gists.count})
       notify_change(target.url, transformed_gists.count, target_ids.count)
    end

    DataDogHelper::gauge_key('github_user_gist_new_target_count', target_ids.count)
    TargetMonitorInstallWorker.perform_async(target_ids) if target_ids.present?
  end

  private

  def notify_change(gh_username, total_count, added_count)
    message = ["Github User #{gh_username} \n #### Total Gist count - #{total_count}"]
    message << "Fresh Gist count - #{added_count}" unless added_count.zero?
    @slack_notifier.notify(message.join("\n"),SlackNotifier::CHANNELS[:USER_TRACKING])
  end
end
