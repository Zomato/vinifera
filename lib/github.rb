class Github

  MAX_ITEMS_PER_PAGE = 100
  BIG_REPO_SIZE_THRESHOLD = 13000 # raw size in kb of source only
  MANUAL_PAGINATION_LIMIT = 50

  INTERNAL_OPTS_KEYS = %i[page_limit item_limit manual_pagination last_id_processed filter_date].freeze
  USER_INFO_CACHE_KEY = 'github_user_info_'.freeze
  REPO_SOURCE_CACHE_KEY = 'repo_source_info_'.freeze
  ACCOUNT_TYPES = {user: 'User', org: 'Organization'}.freeze

  def initialize(opts = {})
    Octokit.configure do |config|
      config.middleware = init_caching_stack(opts)
    end
    @octokit_client = Octokit::Client.new(access_token: github_access_token, per_page: MAX_ITEMS_PER_PAGE)
  end

  def user_info(user_slug)
    Rails.cache.fetch("#{USER_INFO_CACHE_KEY}#{user_slug}", skip_nil: true, expires_in: 1.day) do
      begin
        @octokit_client.user(user_slug)
      rescue Octokit::NotFound
        nil
      end
    end
  end

  def user_events(user_name = '', opts = {})
    execute(opts) { @octokit_client.user_events(user_name, clean_opts(opts)) }
  end

  def user_repos(user_name = '', opts = {})
    execute(opts) { @octokit_client.repositories(user_name, clean_opts(opts)) }
  end

  def user_gists(user_name = '', opts = {})
    execute(opts) { @octokit_client.gists(user_name, clean_opts(opts)) }
  end

  def gist_commits(gist_id, opts = {})
    execute(opts) { @octokit_client.gist_commits(gist_id) }
  end

  def repo_commits(repo_identifier, opts = {})
    execute(opts) { @octokit_client.list_commits(repo_identifier, clean_opts(opts)) }
  end

  def repo_branches(repo_identifier, opts = {})
    execute(opts) { @octokit_client.branches(repo_identifier, clean_opts(opts)) }
  end

  def org_members(org_name, opts = {})
    execute(opts) { @octokit_client.org_members(org_name, clean_opts(opts)) }
  end

  def repo_commits_by_author(repo_identifier, author, opts = {})
    branches = repo_branches(repo_identifier)
    branches.map do |branch|
      repo_commits(repo_identifier, opts.merge({author: author, sha: branch.name}))
    end.flatten!
  end

  def compare_branches(fork_repo, fork_branch, upstream_owner, upstream_branch)
    begin
      @octokit_client.compare(fork_repo, fork_branch, "#{upstream_owner}:#{upstream_branch}")
    rescue Octokit::NotFound
      nil
    end
  end

  def upstream_info(forked_repo_id)
    Rails.cache.fetch("#{REPO_SOURCE_CACHE_KEY}#{forked_repo_id}", skip_nil: true, expires_in: 1.day) do
      begin
        @octokit_client.repo(forked_repo_id).source
      rescue Octokit::NotFound
        nil
      end
    end
  end

  def get(url, opts = {})
    @octokit_client.get(url, opts)
  end

  def user_public_commits(user_name, opts = {})
    (1..MANUAL_PAGINATION_LIMIT).each_with_object([]) do |page_num, result|
      begin
        events = @octokit_client.user_public_events(user_name, clean_opts(opts.merge(page: page_num)))
        events.each do |event|
          return result if opts[:last_id_processed].present? && event.id.to_i <= opts[:last_id_processed].to_i

          if opts[:filter_date].present?
            result << event if event.type == 'PushEvent' && (event.created_at || event.updated_at) >= opts[:filter_date]
          else
            result << event if event.type == 'PushEvent'
          end
        end
      rescue Octokit::UnprocessableEntity
        return result
      end
    end
  end

  private

  def execute(opts = {}, &block)
    begin
      iterate_pagination(opts, yield)
    rescue Octokit::SAMLProtected
      with_token { iterate_pagination(opts, yield) }
    end
  end

  def with_token(access_token = nil, &block)
    original_token = @octokit_client.access_token
    @octokit_client.access_token = access_token
    result = yield
    @octokit_client.access_token = original_token
    result
  end

  def iterate_pagination(opts = {}, result)
    page_limit = opts[:page_limit]
    page_iterated = 1
    last_response = @octokit_client.last_response
    record_limit = opts[:item_limit]

    while should_fetch_more?(page_limit, page_iterated) && can_fetch_more?(last_response)
      last_response = last_response.rels[:next].get
      result.is_a?(Array) ? result += extract_last_response(last_response) : result.items += extract_last_response(last_response)
      page_iterated += 1
      item_count = result.is_a?(Array) ? result.count : result.items.count
      return limit_result_count(result, record_limit.to_i) if record_limit && item_count >= record_limit.to_i
    end
    record_limit ? limit_result_count(result, record_limit.to_i) : result
  end

  def extract_last_response(last_response)
    last_response.data.respond_to?(:items) ? last_response.data.items : last_response.data
  end

  def init_caching_stack(opts)
    Faraday::RackBuilder.new do |builder|
      builder.use Faraday::HttpCache, serializer: Marshal, shared_cache: false, store: Rails.cache unless opts[:skip_cache]
      builder.use Faraday::Request::Retry, exceptions: [Octokit::ServerError]
      builder.use Octokit::Response::RaiseError
      builder.use Octokit::Middleware::FollowRedirects
      builder.use Octokit::Response::FeedParser
      builder.adapter Faraday.default_adapter
    end
  end

  def should_fetch_more?(page_limit, page_iterated)
    page_limit.nil? || page_iterated < page_limit.to_i
  end

  def can_fetch_more?(last_response)
    last_response.rels[:next].present? && @octokit_client.rate_limit.remaining.positive?
  end

  def limit_result_count(result, limit)
    if result.is_a?(Array)
      result[0..limit - 1]
    else
      result.items[0..limit - 1]
    end
  end

  def clean_opts(opts)
    opts.except(*INTERNAL_OPTS_KEYS)
  end

  def github_access_token
    ENV['GITHUB_ACCESS_TOKEN']
  end
end