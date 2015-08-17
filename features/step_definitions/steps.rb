require "widget"
require "widget_exporter"
require "csv"

Given "some widgets" do
  @widget_1 = Widget.new "ABC123", "Left-handed screwdriver", 499
  @widget_2 = Widget.new "DEF456", "Tartan paint", 1249
end

When "I export them to CSV" do
  @csv_path = File.expand_path "../../tmp/widgets.csv", __dir__
  WidgetExporter.export_to @csv_path
end

Then "the CSV file contains information about my widgets" do
  csv = CSV.read @csv_path, headers: true
  expect(csv).to have_row_for(@widget_1).and have_row_for(@widget_2)
end
