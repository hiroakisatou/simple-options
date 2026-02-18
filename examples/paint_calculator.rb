# frozen_string_literal: true

require_relative '../lib/options'
require_relative '../lib/option'

opts = Options.new(description: "Paint Calculator for Hogan's Exercise")
opts.add Option.new(:length, desc: 'Length of the room', short: '-l', long: '--length', required: true)
               .validate { |v| v.to_f > 0 }
               .convert(&:to_f)

opts.add Option.new(:width, desc: 'Width of the room', short: '-w', long: '--width', required: true)
               .validate { |v| v.to_f > 0 }
               .convert(&:to_f)

if __FILE__ == $0 && !ARGV.empty?
  opts.parse!
  area = opts.get(:length) * opts.get(:width)
  gallons = (area / 350.0).ceil
  puts "You will need to purchase #{gallons} gallons to cover #{area} square feet."
end
