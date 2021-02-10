class FileScanResultProcessor
  REPORT_SPLIT_SIZE = 1

  def initialize(target = nil, monitor = nil)
    @target = target
    @monitor = monitor
    @slack_notifier = SlackNotifier.new
    @report_service = ReportService.new
  end

  def process(scan_result, target_url)
    return unless scan_result[:report]

    if @target && @monitor
      report_data = @report_service.create_report(scan_result, @target, @monitor.id)
    else
      report_data = @report_service.create_stray_report(scan_result, target_url)
    end

    scan_result[:report].each_slice(REPORT_SPLIT_SIZE).each do |report_chunk|
      scan_message = report_chunk.map do |chunk|
        ["#{@target.target_type.capitalize}: #{target_url}", "#{report_data&.class} Id - #{report_data&.id}", "Scan result is ```#{process_message(chunk)}```"].join("\n")
      end
      @slack_notifier.notify(scan_message.join("\n"), SlackNotifier::CHANNELS[:VIOLATIONS])
    end
  end

  private

  def process_message(report_chunk)
    [
      "LeakURL - #{report_chunk['leakURL']}",
      "Rule - #{report_chunk['rule']}"
    ].join("\n")
  end
end