require "widget"
require "widget_exporter"
require "csv"

Given "some widgets" do
  @widget_1 = Widget.new "ABC123", "Left-handed screwdriver", 499
  @widget_2 = Widget.new "DEF456", "Tartan paint", 1249
end

When "I export them to CSV" do
  @csv_path = File.expand_path "../../tmp/widgets.csv", __dir__
  WidgetExporter.new(@csv_path).export [@widget_1, @widget_2]
end

Then "the CSV file contains information about my widgets" do
  csv = CSV.read @csv_path, headers: true
  expect(row_for csv, @widget_1).to contain_data_for @widget_1
  expect(row_for csv, @widget_2).to contain_data_for @widget_2
end
