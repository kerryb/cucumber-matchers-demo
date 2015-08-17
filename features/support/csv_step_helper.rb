require "rspec/matchers"

module CsvStepHelper
  def row_for csv, widget
    csv.find {|row| row["Code"] == widget.code }
  end

  RSpec::Matchers.define :have_row_for do |widget|
    match do |csv|
      csv.any? {|row| row["Code"] == widget.code }
    end

    failure_message do
      "Expected CSV to have a row for the widget with code #{widget.code.inspect}"
    end
  end

  RSpec::Matchers.define :contain_data_for do |widget|
    match do |row|
      row["Name"] == widget.name && row["Price"] == widget.price
    end
  end
end
World CsvStepHelper
