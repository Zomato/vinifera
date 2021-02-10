class StrayCodeScanResultProcessor
  REPORT_SPLIT_SIZE = 2

  def initialize
    @slack_notifier = SlackNotifier.new
    @report_service = ReportService.new
  end

  def process(scan_result, url)
    return unless scan_result[:report]

    report_data = @report_service.create_stray_report(scan_result, url)
    scan_result[:report].each_slice(REPORT_SPLIT_SIZE).each do |report_chunk|
      scan_message = report_chunk.map do |chunk|
        ["#{url}", "#{report_data&.class} Id - #{report_data&.id}", "Scan result is ```#{process_message(chunk)}```"].join("\n")
      end
      @slack_notifier.notify(scan_message.join("\n"), SlackNotifier::CHANNELS[:VIOLATIONS])
    end
  end

  private

  def process_message(report_chunk)
    ["LeakURL - #{report_chunk['leakURL']}",
     "Rule - #{report_chunk['rule']}",
     "CommitMessage - #{report_chunk['commitMessage']}",
     "Email - #{report_chunk['email']}",
     "Date - #{report_chunk['date']}"
    ].join("\n")
  end
end