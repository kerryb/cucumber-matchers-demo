Given "some widgets" do
  @widget_1 = Widget.new "ABC123", "Left-handed screwdriver", 499
  @widget_2 = Widget.new "DEF456", "Tartan paint", 1249
end

When "I export them to CSV" do
end

Then "the CSV file contains information about my widgets" do
end
