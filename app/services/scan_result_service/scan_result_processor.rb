module ScanResultService
  class ScanResultProcessor
    REPORT_SPLIT_SIZE = 1
    REPORT_LIMIT = 10

    def initialize(opts = {})
      @slack_notifier = SlackNotifier.new
      @report_service = ReportService.new
      set_options(opts)
    end

    protected

    def process_report(report)
      reports_processed = 0
      report.each_slice(@split_size).each do |report_chunk|
        if reports_processed > @report_notify_limit
          @slack_notifier.notify("Result truncated due to limit - #{@report_notify_limit}")
          return
        end

        scan_message = report_chunk.map do |chunk|
          yield(chunk)
        end

        @slack_notifier.notify(scan_message.join("\n"), SlackNotifier::CHANNELS[:VIOLATIONS])
        reports_processed += 1
      end
    end

    private

    def set_options(opts)
      @split_size = opts[:report_split_size] || REPORT_SPLIT_SIZE
      @report_notify_limit = opts[:report_notify_limit] || REPORT_LIMIT
    end
  end
end