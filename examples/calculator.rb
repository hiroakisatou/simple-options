#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/simple-cli-options'

# 計算機のサンプル - Number型の柔軟性を示す
parser = SimpleOptions::Options.new(
  program_name: 'calculator',
  description: 'Simple calculator with flexible number support'
)

# Number型は整数と浮動小数点数の両方をサポート
parser.number(:add, desc: 'Add two numbers (supports integers and floats)')
parser.number(:multiply, desc: 'Multiply two numbers')
parser.number(:divide, desc: 'Divide two numbers')
parser.integer(:power, desc: 'Raise to power (integer only)')

parser.parse

if parser.get(:add)
  a = parser.get(:add)
  puts "Enter second number:"
  b = gets.chomp.to_f
  result = a + b
  puts "Result: #{a} + #{b} = #{result}"
  puts "Type: #{result.class}"

elsif parser.get(:multiply)
  a = parser.get(:multiply)
  puts "Enter second number:"
  b = gets.chomp.to_f
  result = a * b
  puts "Result: #{a} × #{b} = #{result}"
  puts "Type: #{result.class}"

elsif parser.get(:divide)
  a = parser.get(:divide)
  puts "Enter divisor:"
  b = gets.chomp.to_f
  if b.zero?
    puts "Error: Division by zero"
  else
    result = a / b
    puts "Result: #{a} ÷ #{b} = #{result}"
    puts "Type: #{result.class}"
  end

elsif parser.get(:power)
  base = parser.get(:power)
  puts "Enter exponent:"
  exp = gets.chomp.to_i
  result = base**exp
  puts "Result: #{base}^#{exp} = #{result}"
  puts "Type: #{result.class}"

else
  puts "No operation specified. Use -h for help."
  puts "\nExamples:"
  puts "  ruby calculator.rb -add 3.14    # Float input"
  puts "  ruby calculator.rb -add 42      # Integer input"
  puts "  ruby calculator.rb -multiply 2.5"
  puts "  ruby calculator.rb -power 2"
end
