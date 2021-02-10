class ReportService
  def create_report(scan_report, target, target_monitor_id)
    return unless scan_report[:report]

    Report.create!(target_id: target.id, target_monitor_id: target_monitor_id, run_logs: scan_report[:run_logs], meta_data: scan_report[:report])
  end

  def create_stray_report(scan_report, url)
    return unless scan_report[:report]

    StrayReport.create!(url: url, meta_data: scan_report[:report])
  end
end