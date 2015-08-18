Feature: Demonstration of composing expectations and custom matchers in Cucumber

  Scenario: CSV export of widgets
    Given some widgets
    When I export them to CSV
    Then the CSV file contains information about my widgets
