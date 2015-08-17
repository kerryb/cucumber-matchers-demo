class WidgetExporter
  def initialize path
    @path = path
  end

  def export widgets
    CSV.open @path, "wb", write_headers: true, headers: %w(Code Name Price)  do |csv|
      widgets.each do |widget|
        csv << [widget.code, widget.name, widget.price]
      end
    end
  end
end
