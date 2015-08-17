class WidgetExporter
  def self.export_to path
    CSV.open path, "wb" do |csv|
    end
  end
end
