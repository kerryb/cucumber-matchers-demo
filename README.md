# Using compound expectations and custom matchers in Cucumber

This project demonstrates the way I like to use [RSpec
matchers](http://www.relishapp.com/rspec/rspec-expectations/v/3-3/docs) in
[Cucumber](https://cucumber.io/) features. A lot of the time this would involve
testing web applications with Capybara, but for simplicity this example uses a
simple CSV exporter. The principles are exactly the same, but this way there
are hopefully fewer irrelevant details.

The specific problem I&rsquo;m trying to address is checking several aspects of
expected behaviour at once (in this case it&rsquo;s the values in a row in the CSV
file, but it could be parts of an HTML element, properties of a generated email
message or anything else). I&rsquo;m aiming for a solution that:

* checks several parts of one thing at once, rather than having separate expectations
* reports which individual checks failed, rather than an unhelpful all-or-nothing failure message
* gives useful failure messages for each failed check

You can roughly follow the code through the stages described below by stepping through
the commits, although it might not entirely match at some points.

## TL;DR

* Write [custom matchers](http://www.relishapp.com/rspec/rspec-expectations/v/3-3docs/custom-matchers) so that your step definitions read clearly
* [Override the default failure messages](http://www.relishapp.com/rspec/rspec-expectations/v/3-3/docs/custom-matchers/define-matcher#overriding-the-failure-message) to make them more useful
* [Use compound expectations](http://www.relishapp.com/rspec/rspec-expectations/v/3-3/docs/compound-expectations) to check several related things
* Encapsulate matcher composition in a method, which will itself act like a matcher

## Let&rsquo;s get started! 

The only gems I&rsquo;m using explicitly are `cucumber` (2.0.2) and `rspec-expectations` (3.3.1).

Here&rsquo;s our first (and only) feature:

```gherkin
Feature: Demonstration of composing expectations and custom matchers in Cucumber

  Scenario: CSV export of widgets
    Given some widgets
    When I export them to CSV
    Then the CSV file contains information about my widgets
```

And the corresponding step definitions:

```ruby
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
  csv = CSV.read @csv_path
  expect(csv).to have_row_for @widget_1
  expect(csv).to have_row_for @widget_2
end
```

When we run this, it fails because the `have_row_for` matcher doesn&rsquo;t exist:

    Scenario: CSV export of widgets
      Given some widgets                                      # features/step_definitions/steps.rb:5
      When I export them to CSV                               # features/step_definitions/steps.rb:10
      Then the CSV file contains information about my widgets # features/step_definitions/steps.rb:15
        expected [] to respond to `has_row_for?` (RSpec::Expectations::ExpectationNotMetError)
        ./features/step_definitions/steps.rb:17:in `/^the\ CSV\ file\ contains\ information\ about\ my\ widgets$/'
        features/demo.feature:6:in `Then the CSV file contains information about my widgets'

## Creating a custom matcher

Let&rsquo;s implement a matcher in a file under `features/support`. We&rsquo;ll follow the
normal convention of creating a module and mixing it into Cucumber&rsquo;s `World`,
which would (if we had more modules) make it easier to find things in
stack traces.

```ruby
require "rspec/matchers"

module CsvStepHelper
  RSpec::Matchers.define :have_row_for do |widget|
    match do |csv|
    end
  end
end
World CsvStepHelper
```

The `match` method is currently empty, which means it&rsquo;ll return nil (which is
falsy) and the expectation will fail:

    Scenario: CSV export of widgets
      Given some widgets                                      # features/step_definitions/steps.rb:5
      When I export them to CSV                               # features/step_definitions/steps.rb:10
      Then the CSV file contains information about my widgets # features/step_definitions/steps.rb:15
        expected [] to have row for #<struct Widget code="ABC123", name="Left-handed screwdriver", price=499> (RSpec::Expectations::ExpectationNotMetError)
        ./features/step_definitions/steps.rb:17:in `/^the\ CSV\ file\ contains\ information\ about\ my\ widgets$/'
        features/demo.feature:6:in `Then the CSV file contains information about my widgets'

## Composing multiple matchers

Note that as soon as the first expectation fails, the scenario stops executing
&ndash; we don&rsquo;t get told that the second row is also missing.

In unit tests I tend to try to stick to the &lsquo;one expectation per
test&rsquo; rule, but in features it often makes sense to group several
expectations into a single step, to keep unecessary details out of the scenario
declaration. If we want to see both failures at once, we can use RSpec&rsquo;s
[compound expectations](http://www.relishapp.com/rspec/rspec-expectations/v/3-3/docs/compound-expectations)
to combine them with `and`:

```ruby
Then "the CSV file contains information about my widgets" do
  csv = CSV.read @csv_path
  expect(csv).to have_row_for(@widget_1).and have_row_for(@widget_2)
end
```

    Then the CSV file contains information about my widgets # features/step_definitions/steps.rb:15
      expected [] to have row for #<struct Widget code="ABC123", name="Left-handed screwdriver", price=499> and expected [] to have row for #<struct Widget code="DEF456", name="Tartan paint", price=1249> (RSpec::Expectations::ExpectationNotMetError)

## Improving the failure messages

OK, that works, but the failure message isn&rsquo;t great. If the CSV actually contained any data, it gets even worse (I haven&rsquo;t shown the code under test here, as it&rsquo;s not really relevant, but you can find it in `lib`). Here it is with just headers and a single empty row:

    Then the CSV file contains information about my widgets # features/step_definitions/steps.rb:15
      expected [["Code", "Name", "Price"], [nil, nil, nil]] to have row for #<struct Widget code="ABC123", name="Left-handed screwdriver", price=499> and expected [["Code", "Name", "Price"], [nil, nil, nil]] to have row for #<struct Widget code="DEF456", name="Tartan paint", price=1249> (RSpec::Expectations::ExpectationNotMetError)

Let&rsquo;s see what we can do about that.

```ruby
RSpec::Matchers.define :have_row_for do |widget|
  match do |csv|
  end

  failure_message do
    "expected CSV to have a row for the widget with code #{widget.code.inspect}"
  end
end
```

    expected CSV to have a row for the widget with code "ABC123" and expected CSV to have a row for the widget with code "DEF456" (RSpec::Expectations::ExpectationNotMetError)

Much better!

While we&rsquo;re there, it&rsquo;s probably about time we made the matcher actually test something.

```ruby
RSpec::Matchers.define :have_row_for do |widget|
  match do |csv|
    csv.any? {|row| row["Code"] == widget.code }
  end

  failure_message do
    "expected CSV to have a row for the widget with code #{widget.code.inspect}"
  end
end
```

Now if we arrange for the widget code to be written to the CSV (but not its
name or price), the feature passes. We should probably test the rest of the row
content too. Here&rsquo;s the expanded step definition:

```ruby
Then "the CSV file contains information about my widgets" do
  csv = CSV.read @csv_path, headers: true
  expect(csv).to have_row_for(@widget_1).and have_row_for(@widget_2)
  expect(row_for csv, @widget_1).to contain_data_for @widget_1
  expect(row_for csv, @widget_2).to contain_data_for @widget_2
end
```

And in the helper module we need a `row_for` method and another custom matcher:

```ruby
module CsvStepHelper
  def row_for csv, widget
    csv.find {|row| row["Code"] == widget.code }
  end

  # ...

  RSpec::Matchers.define :contain_data_for do |widget|
    match do |row|
      row["Name"] == widget.name && row["Price"] == widget.price.to_s
    end
  end
end
```

I&rsquo;ve chosen to first check that the required rows are there, then separately
retrieve each row and check its contents. As we&rsquo;ll see shortly, checking
expectations against the individual rows makes it much easier to write
expectations than passing the whole CSV around, but the `have_row_for` checks
we&rsquo;ve already implemented are arguably redundant. We&rsquo;ll consider getting rid of
them later.

This fails as expected, but once again the failure message could be more
helpful:

    Then the CSV file contains information about my widgets # features/step_definitions/steps.rb:15
      expected #<CSV::Row "Code":"ABC123" "Name":nil "Price":nil> to contain data for #<struct Widget code="ABC123", name="Left-handed screwdriver", price=499> (RSpec::Expectations::ExpectationNotMetError)

## Composing matchers again

By default the message just tells us that the expectation failed, not the specific things it was looking for or what it found instead. We&rsquo;ll fix that in a minute, but there&rsquo;s another problem too: because we&rsquo;re linking two separate assertions with `&&`, if the name&rsquo;s not found then it doesn&rsquo;t even check the price. Let&rsquo;s address that by using compound expectations again &ndash; as a side effect that will also make it easier to improve the messages.

```ruby
Then "the CSV file contains information about my widgets" do
  csv = CSV.read @csv_path, headers: true
  expect(csv).to have_row_for(@widget_1).and have_row_for(@widget_2)
  expect(row_for csv, @widget_1).to contain_name_of(@widget_1).and contain_price_of(@widget_1)
  expect(row_for csv, @widget_2).to contain_name_of(@widget_2).and contain_price_of(@widget_2)
end
```

```ruby
RSpec::Matchers.define :contain_name_of do |widget|
  match do |row|
    row["Name"] == widget.name
  end
end

RSpec::Matchers.define :contain_price_of do |widget|
  match do |row|
    row["Price"] == widget.price.to_s
  end
end
```

This allows us to check both columns at once, but if anything, it makes the failure message even worse:

    expected #<CSV::Row "Code":"ABC123" "Name":nil "Price":nil> to contain name of #<struct Widget code="ABC123", name="Left-handed screwdriver", price=499> and expected #<CSV::Row "Code":"ABC123" "Name":nil "Price":nil> to contain price of #<struct Widget code="ABC123", name="Left-handed screwdriver", price=499> (RSpec::Expectations::ExpectationNotMetError)

## Improving failure messages again

Now we&rsquo;ve split the check into two separate matchers though, it&rsquo;s easy to make the messages more useful:

```ruby
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
```

    expected 'Name' column in row for "ABC123" to be "Left-handed screwdriver", but got nil and expected 'Price' column in row for "ABC123" to be '499', but got nil (RSpec::Expectations::ExpectationNotMetError)


Now if we write the correct name to the CSV file, but not the price, the
message just tells about the failed expectation:

    expected 'Price' column in row for "ABC123" to be 499, but got nil (RSpec::Expectations::ExpectationNotMetError)

## Factoring out matcher composition

We don&rsquo;t really want to have to repeat the detail of checking the two fields in
the step definition though. Fortunately this is easy to fix &ndash; just
extract the composition to a method, which itself acts as a matcher:

```ruby
Then "the CSV file contains information about my widgets" do
  csv = CSV.read @csv_path, headers: true
  expect(csv).to have_row_for(@widget_1).and have_row_for(@widget_2)
  expect(row_for csv, @widget_1).to contain_data_for @widget_1
  expect(row_for csv, @widget_2).to contain_data_for @widget_2
end
```

```ruby
module CsvStepHelper
  # ...

  def contain_data_for widget
    contain_name_of(widget).and contain_price_of(widget)
  end

  # ...
end
```

# Eliminating a nasty nil

The only thing left now is to remove those redundant checks for the existence
of rows. The `have_row_for` matcher can be deleted, and the calls to it removed
from the step definition:

```ruby
Then "the CSV file contains information about my widgets" do
  csv = CSV.read @csv_path, headers: true
  expect(row_for csv, @widget_1).to contain_data_for @widget_1
  expect(row_for csv, @widget_2).to contain_data_for @widget_2
end
```

If we force it to fail by not writing the second widget to the CSV file, the
failure message is less than halpful:

    Then the CSV file contains information about my widgets # features/step_definitions/steps.rb:15
      undefined method `[]' for nil:NilClass (NoMethodError)
      ./features/support/csv_step_helper.rb:14:in `block (2 levels) in <module:CsvStepHelper>'

Let&rsquo;s make sure it fails early, rather than leaving that `nil` lying around for
people to trip over:

```ruby
def row_for csv, widget
  csv.find {|row| row["Code"] == widget.code } or fail "no row found in CSV for widget with code #{widget.code.inspect}"
end
```

    Then the CSV file contains information about my widgets # features/step_definitions/steps.rb:15
      no row found in CSV for widget with code "DEF456" (RuntimeError)
      ./features/support/csv_step_helper.rb:5:in `row_for'

Much better!

## Wrapping it all up

Here&rsquo;s the final code:

### features/demo.feature

```gherkin
Feature: Demonstration of composing expectations and custom matchers in Cucumber

  Scenario: CSV export of widgets
    Given some widgets
    When I export them to CSV
    Then the CSV file contains information about my widgets
```

### features/step_definitions/steps.rb

```ruby
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
```

### features/support/csv_step_helper.rb

```ruby
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
```
