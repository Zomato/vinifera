# frozen_string_literal: true

require 'datadog/statsd'
$statsd = Datadog::Statsd.new('localhost', 8125)
