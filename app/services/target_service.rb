class TargetService

  class UnProcessableTarget < Exception;
  end

  class RecoverableTarget < Exception;
  end

  def register(params)
    params = [params] unless params.is_a? Array
    params.present? ? Target.insert_all(params) : []
  end

  def monitor(target_monitor)
    target = target_monitor.target
    target_monitor_trigger = resolve_target_monitor(target)
    begin
      target_monitor_trigger.new(target_monitor).monitor
    rescue Octokit::UnavailableForLegalReasons, Octokit::NotFound => err
      raise UnProcessableTarget, err.message
    rescue Octokit::Conflict => err
      raise RecoverableTarget, err.message
    end
    target_key = resolve_counter_key(target)
    DataDogHelper::increment_key(target_key) if target_key
  end

  def target_exists?(attrs)
    Target.exists?(attrs)
  end

  def fetch_target(params = {})
    Target.find_by(params)
  end

  private

  def resolve_counter_key(target)
    if target.github? && target.gist?
      'github_gist_monitor_count'
    elsif target.github? && target.repo?
      'github_repo_monitor_count'
    elsif target.github? && target.user?
      'github_user_monitor_count'
    end
  end

  def resolve_target_monitor(target)
    if target.github? && target.gist?
      GithubService::Gist::Monitor
    elsif target.github? && target.repo?
      GithubService::Repo::Monitor
    elsif target.github? && target.user?
      GithubService::User::Monitor
    elsif target.asana? && target.workspace?
      AsanaService::Workspace::Monitor
    elsif target.z_staging?
      GeneralTrackerService::Scan::ZStaging::Monitor
    end
  end
end
