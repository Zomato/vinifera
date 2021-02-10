class GithubUserRepoSyncer
  def initialize
    @github = Github.new
    @transformer = TargetTransformer.new
    @service = TargetService.new
    @slack_notifier = SlackNotifier.new
  end

  def sync_repos(target)
    gh_username = target.slug
    repos = @github.user_repos(gh_username)
    transformed_repos = @transformer.transform_all(repos, Target.providers[:github], Target.target_types[:repo])
    result = @service.register(transformed_repos)
    target_ids = result.pluck('id')

    if target.meta_data.try(:[], 'repo_count').to_i != transformed_repos.count
      target.add_meta_data!({repo_count: transformed_repos.count})
      notify_change(target.url, transformed_repos.count, target_ids.count)
    end


    DataDogHelper::gauge_key('github_user_repo_new_target_count', target_ids.count)
    TargetMonitorInstallWorker.perform_async(target_ids) if target_ids.present?
  end

  private

  def notify_change(gh_username, total_count, added_count)
    message = ["Github User #{gh_username} \n Total Repo count - #{total_count}"]
    message << "Fresh Repo count - #{added_count}" unless added_count.zero?
    @slack_notifier.notify(message.join("\n"),SlackNotifier::CHANNELS[:USER_TRACKING])
  end

end
