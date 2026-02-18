# frozen_string_literal: true

require 'rspec'
require_relative 'option'
require_relative 'options'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end
