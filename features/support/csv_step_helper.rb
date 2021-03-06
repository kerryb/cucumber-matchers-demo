require "rspec/matchers"

module CsvStepHelper
  def row_for csv, widget
    csv.find {|row| row["Code"] == widget.code } or fail "no row found in CSV for widget with code #{widget.code.inspect}"
  end

  def contain_data_for widget
    contain_name_of(widget).and contain_price_of(widget)
  end

  RSpec::Matchers.define :contain_name_of do |widget|
    match do |row|
      row["Name"] == widget.name
    end

    failure_message do |row|
      "expected 'Name' column in row for #{widget.code.inspect} to be #{widget.name.inspect}, but got #{row["Name"].inspect}"
    end
  end

  RSpec::Matchers.define :contain_price_of do |widget|
    match do |row|
      row["Price"] == widget.price.to_s
    end

    failure_message do |row|
      "expected 'Price' column in row for #{widget.code.inspect} to be #{widget.price.to_s.inspect}, but got #{row["Price"].inspect}"
    end
  end
end
World CsvStepHelper
