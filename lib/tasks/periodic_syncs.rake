namespace :periodic_syncs do
  task sync_github_users: :environment do |_, _args|
    Rails.logger.info '[Period-Syncs-Sync-Github-Users] Syncing Github Users '
    github_user_syncer = GithubUserSyncer.new
    github_user_syncer.sync_org_users(ENV['VINIFERA_ORG_NAME'])

    Rails.logger.info '[Period-Syncs-Sync-Github-Users] Sync complete for Github Users '
  end

  task sync_model_stats: :environment do |_, _args|
    ModelMetrics.instance.push_stats
  end
end
