class GithubUserSyncer
  def initialize
    @github = Github.new
    @transformer = TargetTransformer.new
    @service = TargetService.new
  end

  def sync_org_users(org_name)
    users = @github.org_members(org_name)
    transformed_users = @transformer.transform_all(users, Target.providers[:github], Target.target_types[:user])
    result = @service.register(transformed_users)
    target_ids = result.pluck('id')
    DataDogHelper::gauge_key('github_user_new_target_count', target_ids.count)
    TargetMonitorInstallWorker.perform_async(target_ids) if target_ids.present?
  end
end
