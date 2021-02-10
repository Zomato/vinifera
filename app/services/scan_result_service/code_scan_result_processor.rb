module ScanResultService
  class CodeScanResultProcessor < ScanResultService::ScanResultProcessor
    REPORT_SPLIT_SIZE = 1
    NOTIFY_CHUNK_LIMIT = 10

    def initialize(target, monitor)
      @target = target
      @monitor = monitor
      super()
    end

    def process(scan_result)
      return unless scan_result[:report]

      report_data = @report_service.create_report(scan_result, @target, @monitor.id)
      process_report(scan_result[:report]) do |chunk|
        format_message(chunk, report_data)
      end
    end

    private

    def format_message(chunk, report_data)
      ["#{@target.target_type.capitalize}: #{@target.url}", "#{report_data&.class} Id - #{report_data&.id}", "Scan result is ```#{process_message(chunk)}```"].join("\n")
    end

    def process_message(report_chunk)
      ["LeakURL - #{report_chunk['leakURL']}",
       "Rule - #{report_chunk['rule']}",
       "CommitMessage - #{report_chunk['commitMessage'].truncate(120)}",
       "Offender - #{report_chunk['offender'].truncate(100)}",
       "Email - #{report_chunk['email']}",
       "Date - #{report_chunk['date']}"
      ].join("\n")
    end
  end
end