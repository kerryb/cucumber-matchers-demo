require "rspec/matchers"

module CsvStepHelper
  RSpec::Matchers.define :have_row_for do |widget|
    match do |csv|
      csv.any? {|row| row["Code"] == widget.code }
    end

    failure_message do
      "Expected CSV to have a row for the widget with code #{widget.code.inspect}"
    end
  end
end
World CsvStepHelper
