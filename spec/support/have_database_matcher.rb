# frozen_string_literal: true

RSpec::Matchers.define :have_database do |expected|
  match do |conn|
    list = conn.execute('pragma database_list')
    @result = File.basename(list.first&.[]('file'))
    @result == expected
  end
  description do
    "be connected to #{expected}"
  end
  failure_message do |actual|
    "expected that #{actual} would be connected to #{expected}, found #{@result}"
  end
end
