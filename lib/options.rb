# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require_relative 'option'

# ==========================================
# 2. Options クラス（オプションの管理と解析）
# ==========================================
class Options
  extend T::Sig

  sig { params(description: String).void }
  def initialize(description: '')
    @description = T.let(description, String)
    @options = T.let([], T::Array[Option])
    @values = T.let({}, T::Hash[Symbol, T.untyped])
    @program_name = T.let(File.basename($0), String)
  end

  sig { params(option: Option).void }
  def add(option)
    @options << option
  end

  sig { void }
  def show_help
    puts "#{@description}\n\n" unless @description.empty?
    puts "Usage:\n  #{@program_name} [flags]\n\n"
    puts 'Flags:'
    @options.each do |opt|
      flags = [
        opt.short.empty? ? nil : opt.short,
        opt.long.empty? ? nil : opt.long
      ].compact.join(', ')
      printf "  %-20s %s\n", flags, opt.desc
    end
  end

  sig { params(argv: T.nilable(T::Array[String])).void }
  def parse!(argv = nil)
    argv = T.let(argv || ARGV, T::Array[String])

    if argv.include?('-h') || argv.include?('--help')
      show_help
      exit 0
    end

    @options.each do |opt|
      # short または long に一致する引数を探す
      idx = argv.find_index { |arg| arg == opt.short || arg == opt.long }

      if idx && argv[idx + 1]
        @values[opt.name] = opt.process(T.must(argv[idx + 1]))
      elsif opt.required_flag
        warn "Error: Missing required option: #{opt.long.empty? ? opt.short : opt.long}"
        exit 1
      end
    end
  end

  sig { params(name: Symbol).returns(T.untyped) }
  def get(name)
    @values[name]
  end
end
