class CodeScanner
  BASE_IMAGE = 'zricethezav/gitleaks'.freeze
  REPO_TAG = 'zricethezav/gitleaks:v7.2.0'.freeze
  CUSTOM_RULE_PATH = '/data/gitleaks.toml'.freeze
  POLL_INTERVAL = 2.seconds
  TTL = 10.minutes
  CPU_SHARE = '0.4'.freeze
  CPU_SET_CPUS = '0'.freeze # Limit only one core to this container

  MEMORY_LIMIT = 1024 * 1024 * 1024 # 1 GB

  class ZombieScan < RuntimeError; end

  class ReaperKill < RuntimeError; end

  def scan(repo, opts = {})
    command = Shellwords.split generate_command(opts.merge({ repo: repo, report: report_file, clone_location: clone_location }))
    container_opts = { 'Memory': MEMORY_LIMIT, 'CpusetCpus': CPU_SET_CPUS, 'Cpus': CPU_SHARE, 'Cmd': command, 'Image': BASE_IMAGE }
    execute_container(container_opts)
  end

  def scan_file(file, opts = {})
    command = Shellwords.split generate_command(opts.merge({ file: scan_file_location, report: report_file }))
    container_opts = { 'Memory': MEMORY_LIMIT, 'CpusetCpus': CPU_SET_CPUS, 'Cpus': CPU_SHARE, 'Cmd': command, 'Image': BASE_IMAGE }
    execute_container(container_opts, { file_path: file })
  end

  private

  def execute_container(container_opts, opts = {})
    container = prepare_container(container_opts, opts)
    monitor_container(container)
    exit_code = container.refresh!.json['State']['ExitCode'].to_i
    result = {}
    case exit_code
    when 0
      result.merge!({ run_logs: container.logs(stdout: true), report: fetch_report(container) })
    when 1
      raise RuntimeError, container.logs(stderr: true)
    end
    container.delete
    result
  end

  def monitor_container(container)
    container.start!
    while Docker::Container.all.find { |e| e.id == container.id }
      sleep POLL_INTERVAL
      # If container is taking too long to scan, kill it
      container_creation = container.info['Created']
      if container_creation && (Time.zone.now.to_i - container_creation).seconds >= TTL
        container.kill!
        raise ReaperKill, 'Container took too long to scan.'
      end

      # If container is idle, kill it and raise custom exception
      if container.stats['pids_stats'].nil? && container.stats['cpu_stats']['cpu_usage']['total_usage'].to_i.positive?
        container.kill!
        raise ZombieScan, 'Container seems to be idle' unless container.stats['pid_stats']
      end
    end
  end

  def fetch_report(container)
    begin
      JSON.parse container.read_file(report_file)
    rescue Docker::Error::NotFoundError
      nil
    end
  end

  def prepare_container(container_opts, opts = {})
    ensure_image
    container = Docker::Container.create(container_opts)
    container.store_file(scan_file_location, File.read(opts[:file_path])) if opts[:file_path]
    container.store_file(CUSTOM_RULE_PATH, File.read(custom_config_path))
    container
  end

  def generate_command(opts)
    if opts[:file]
      "--path #{opts[:file]} --report #{opts[:report]} --config-path #{CUSTOM_RULE_PATH} --no-git --leaks-exit-code=0"
    elsif opts[:repo]
      return "--clone-path #{opts[:clone_location]} --report #{opts[:report]} -r #{opts[:repo]} --commit #{opts[:commit_id]} --config-path #{CUSTOM_RULE_PATH} --leaks-exit-code=0" if opts[:commit_id] and opts[:only_commit]
      return "--clone-path #{opts[:clone_location]} --clone-path --report #{opts[:report]} -r #{opts[:repo]} --commit-from #{opts[:commit_id]} --config-path #{CUSTOM_RULE_PATH} --leaks-exit-code=0" if opts[:commit_id] and opts[:from_commit]

      "--clone-path #{opts[:clone_location]} --report #{opts[:report]} -r #{opts[:repo]} --config-path #{CUSTOM_RULE_PATH} --leaks-exit-code=0"
    end
  end

  def custom_config_path
    @custom_config ||= File.join(Rails.root, 'config', 'gitleaks_rules.toml')
  end

  def report_file
    @report_file ||= tmp_file
  end

  def clone_location
    @clone_location ||= tmp_file
  end

  def scan_file_location
    @scan_file_location ||= tmp_file
  end

  def tmp_file
    File.join('/', 'tmp', SecureRandom.hex)
  end

  def ensure_image
    Docker::Image.exist?(REPO_TAG) || Docker::Image.create(fromImage: BASE_IMAGE, tag: 'v7.2.0')
  end

end
