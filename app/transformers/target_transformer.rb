class TargetTransformer

  def transform(external_data, provider, type)
    if provider == Target.providers[:github]
      github_transformer(external_data, type)
    end
  end

  def transform_all(external_data, provider, type)
    external_data.map do |data|
      transform(data, provider, type)
    end
  end

  private

  def github_transformer(data, type)
    if type == Target.target_types[:user]
      transform_github_user(data)
    elsif type == Target.target_types[:repo]
      transform_github_repo(data)
    elsif type == Target.target_types[:gist]
      transform_github_gist(data)
    end
  end

  def transform_github_user(data)
    {
      provider: Target.providers[:github],
      external_id: data.id,
      url: data.html_url,
      slug: data.login,
      meta_data: data.to_h.slice(:score, :avatar_url),
      status: Target.statuses[:active],
      target_type: Target.target_types[:user],
      created_at: Time.zone.now,
      updated_at: Time.zone.now,
    }
  end

  def transform_github_repo(data)
    {
      provider: Target.providers[:github],
      external_id: data.id,
      url: data.html_url,
      slug: data.full_name,
      meta_data: data.to_h.slice(:fork, :license, :archived, :disabled, :size),
      status: Target.statuses[:active],
      target_type: Target.target_types[:repo],
      created_at: Time.zone.now,
      updated_at: Time.zone.now,
    }
  end

  def transform_github_gist(data)
    {
      provider: Target.providers[:github],
      external_id: data.id,
      url: data.html_url,
      meta_data: data.to_h.slice(:files, :description),
      status: Target.statuses[:active],
      target_type: Target.target_types[:gist],
      created_at: Time.zone.now,
      updated_at: Time.zone.now,
    }
  end

end