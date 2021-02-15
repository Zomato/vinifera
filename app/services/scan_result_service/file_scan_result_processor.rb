module ScanResultService
  class FileScanResultProcessor < ScanResultService::ScanResultProcessor
    REPORT_SPLIT_SIZE = 1

    def initialize(target = nil, monitor = nil)
      @target = target
      @monitor = monitor
      super()
    end

    def process(scan_result, target_url)
      return unless scan_result[:report]

      if @target && @monitor
        report_data = @report_service.create_report(scan_result, @target, @monitor.id)
      else
        report_data = @report_service.create_stray_report(scan_result, target_url)
      end

      process_message(scan_result[:report]) do |chunk|
        format_message(target_url, chunk, report_data)
      end
    end

    private

    def format_message(ctx_identifier, chunk, report_data)
      ["#{@target.target_type.capitalize}: #{ctx_identifier}", "#{report_data&.class} Id - #{report_data&.id}", "Scan result is ```#{process_message(chunk)}```"].join("\n")
    end

    def process_message(report_chunk)
      [
        "LeakURL - #{report_chunk['leakURL']}",
        "Rule - #{report_chunk['rule']}",
        "Offender - #{report_chunk['offender'].truncate(100)}",
      ].join("\n")
    end
  end
end
