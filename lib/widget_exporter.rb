class WidgetExporter
  def self.export_to path
    CSV.open path, "wb", write_headers: true, headers: %w(Code Name Price)  do |csv|
      csv << [nil, nil, nil]
    end
  end
end
