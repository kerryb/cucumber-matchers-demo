require "rspec/matchers"

module CsvStepHelper
  RSpec::Matchers.define :have_row_for do |widget|
    match do |csv|
    end
  end
end
World CsvStepHelper
