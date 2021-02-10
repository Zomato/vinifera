module ScanResultService
  class StrayCodeScanResultProcessor < ScanResultService::ScanResultProcessor

    def process(scan_result, url)
      return unless scan_result[:report]

      report_data = @report_service.create_stray_report(scan_result, url)
      process_report(scan_result[:report]) do |report_chunk|
        format_message(url, report_chunk, report_data)
      end
    end

    private

    def format_message(ctx_identifier, chunk, report_data)
      ["#{ctx_identifier}", "#{self.class} Id - #{report_data&.id}", "Scan result is ```#{process_message(chunk)}```"].join("\n")
    end

    def process_message(report_chunk)
      ["LeakURL - #{normalize_leak_url(report_chunk['leakURL'])}",
       "Rule - #{report_chunk['rule']}",
       "CommitMessage - #{report_chunk['commitMessage'].truncate(120)}",
       "Offender - #{report_chunk['offender'].truncate(100)}",
       "Email - #{report_chunk['email']}",
       "Date - #{report_chunk['date']}"
      ].join("\n")
    end

    def normalize_leak_url(leak_url)
      leak_url.gsub('.git', '')
    end
  end
end