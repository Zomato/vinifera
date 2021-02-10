class Target < ApplicationRecord
  has_many :target_revisions
  has_many :target_monitors

  enum target_type: { user: 'user', repo: 'repo', gist: 'gist' }
  enum status: { active: 'active', archived: 'archived', deleted: 'deleted' }
  enum provider: { github: 'github' }

  def add_meta_data!(data)
    self.meta_data = {} if self.meta_data.nil?
    self.meta_data.merge!(data)
    self.save!
  end

  def meta_exists?(key)
    self.meta_data.try(:[], key)
  end

  def big_github_repo?
    self.github? && self.meta_exists?('size') && self.meta_exists?('size') >= Github::BIG_REPO_SIZE_THRESHOLD
  end

  def github_fork?
    self.meta_exists?('fork')
  end

  def normal_github_fork?
    github_fork? && !big_github_repo?
  end

  def big_github_fork?
    github_fork? && big_github_repo?
  end
end
