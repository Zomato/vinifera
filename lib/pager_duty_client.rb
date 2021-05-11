class PagerDutyClient
  DEFAULT_API_VERSION = 2

  INCIDENT_SEVERITIES = { critical: 'critical', error: 'error', warning: 'warning', info: 'info' }.freeze

  def initialize(opts = {})
    @client = Pagerduty.build(integration_key: opts[:integration_key] || ENV['DEFAULT_PD_INTEGRATION_KEY'], api_version: opts[:api_version] || DEFAULT_API_VERSION)
  end

  def create_incident(opts = {})
    default_opts = { summary: 'Default Summary', source: 'Vinifera', severity: INCIDENT_SEVERITIES[:critical] }
    @client.trigger(default_opts.merge(opts))
  end
end


