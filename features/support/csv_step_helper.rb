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

  def contain_data_for widget
    contain_name_of(widget).and contain_price_of(widget)
  end

  RSpec::Matchers.define :contain_name_of do |widget|
    match do |row|
      row["Name"] == widget.name
    end

    failure_message do |row|
      "Expected 'Name' column in row for #{widget.code.inspect} to be #{widget.name.inspect}, but got #{row["Name"].inspect}"
    end
  end

  RSpec::Matchers.define :contain_price_of do |widget|
    match do |row|
      row["Price"] == widget.price
    end

    failure_message do |row|
      "Expected 'Price' column in row for #{widget.code.inspect} to be #{widget.price.inspect}, but got #{row["Price"].inspect}"
    end
  end
end
World CsvStepHelper
