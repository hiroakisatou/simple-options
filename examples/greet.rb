# frozen_string_literal: true

require_relative '../lib/options'
require_relative '../lib/option'

opts = Options.new(description: 'Print a greeting.')
opts.add Option.new(:name, short: '-n', long: '--name', desc: 'Name to greet', required: true)
opts.add Option.new(:count, short: '-c', long: '--count', desc: 'Repeat count')
       .validate { |v| v.to_i.positive? ? nil : 'Please input positive number' }
               .convert(&:to_i)

if __FILE__ == $0 && !ARGV.empty?
  opts.parse!
  msg = "Hello, #{opts.get(:name)}!"
  count = opts.get(:count) || 1
  count.times { puts msg }
end
