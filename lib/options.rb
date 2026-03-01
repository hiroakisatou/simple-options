# frozen_string_literal: true
# typed: strict

require 'sorbet-runtime'
require_relative 'option'

module SimpleOptions
  class Options
    extend T::Sig

    # initialize で引数をオプション（nil許容）に変更
    sig { params(program_name: T.nilable(String), description: T.nilable(String)).void }
    def initialize(program_name: nil, description: nil)
      # 指定がなければ実行スクリプト名を取得
      @program_name = T.let(program_name || File.basename($PROGRAM_NAME), String)
      @description = T.let(description, T.nilable(String))
      @options = T.let([], T::Array[Option])
      @values = T.let({}, T::Hash[Symbol, T.untyped])
    end

    sig { params(name: String).void }
    def program_name(name) = @program_name = name

    sig { params(desc: String).void }
    def description(desc) = @description = desc

    # --- 型明示的な定義メソッド ---

    sig { params(name: Symbol, desc: String, short: String, long: String, required: T::Boolean, default: T.nilable(Integer)).returns(Option) }
    def integer(name, desc: '', short: '', long: '', required: false, default: nil)
      add_internal(name, desc, short, long, required, default || 0, type: :integer)
    end

    sig { params(name: Symbol, desc: String, short: String, long: String, required: T::Boolean, default: T.nilable(T::Boolean)).returns(Option) }
    def boolean(name, desc: '', short: '', long: '', required: false, default: nil)
      add_internal(name, desc, short, long, required, default.nil? ? false : default, type: :boolean)
    end

    sig { params(name: Symbol, desc: String, short: String, long: String, required: T::Boolean, default: T.untyped).returns(Option) }
    def number(name, desc: '', short: '', long: '', required: false, default: nil)
      add_internal(name, desc, short, long, required, default || 0, type: :number)
    end

    sig { params(name: Symbol, desc: String, short: String, long: String, required: T::Boolean, default: T.nilable(String)).returns(Option) }
    def string(name, desc: '', short: '', long: '', required: false, default: nil)
      add_internal(name, desc, short, long, required, default || '', type: :string)
    end

    # 汎用的なoptionメソッド（typeを省略可能、デフォルトは:string）
    sig { params(name: Symbol, desc: String, short: String, long: String, required: T::Boolean, default: T.untyped, type: Symbol).returns(Option) }
    def option(name, desc: '', short: '', long: '', required: false, default: nil, type: :string)
      add_internal(name, desc, short, long, required, default, type: type)
    end

    # --- ヘルプ表示（レイアウト改良版） ---

    sig { void }
    def show_help
      # 1. プログラム名
      puts @program_name

      # 2. 説明文（存在する場合のみ、改行を入れて表示）
      if @description && !@description.to_s.empty?
        puts ''
        puts @description
      end

      # 3. Usage
      puts ''
      puts 'Usage:'
      puts "  #{@program_name} [flags]"

      # 4. Flags
      puts ''
      puts 'Flags:'
      @options.each do |opt|
        short_part = opt.short.empty? ? '    ' : "#{opt.short},"
        long_part  = opt.long.empty? ? '' : " #{opt.long}"

        flag_str = "  #{short_part}#{long_part}"
        printf "%-25<flag>s %<desc>s\n", flag: flag_str, desc: opt.desc
      end
    end

    # --- パース処理 ---

    sig { params(argv: T.nilable(T::Array[String])).void }
    def parse(argv = nil)
      args = T.let(argv || ARGV.dup, T::Array[String])

      # ヘルプフラグが指定されている場合は、他のオプションをパースせず即座にヘルプを表示
      if args.include?('-h') || args.include?('--help')
        show_help
        exit 0
      end

      @options.each { |opt| @values[opt.name] = opt.default }

      while args.any?
        arg = T.must(args.shift)

        unless arg.start_with?('-')
          (@values[:args] ||= []) << arg
          next
        end

        opt = @options.find { |o| o.short == arg || o.long == arg }

        if opt.nil?
          warn "Error: Unknown option '#{arg}'"
          puts ''
          show_help
          exit 1
        end

        # 既に値が設定されている場合はスキップ（最初の出現を優先）
        if @values.key?(opt.name) && @values[opt.name] != opt.default
          # 値を消費する必要がある
          if opt.type == :boolean
            next_arg = args.first
            args.shift if next_arg && Option::BOOLEAN_MAP.key?(next_arg.downcase)
          else
            args.shift
          end
          next
        end

        begin
          if opt.type == :boolean
            next_arg = args.first
            @values[opt.name] = if next_arg && Option::BOOLEAN_MAP.key?(next_arg.downcase)
                                  opt.process(T.must(args.shift))
                                else
                                  true
                                end
          else
            val = args.shift
            if val.nil? || val.start_with?('-')
              warn "Error: Missing value for option '#{arg}'"
              exit 1
            end
            @values[opt.name] = opt.process(val)
          end
        rescue ArgumentError => e
          warn "Error: #{e.message}"
          exit 1
        end
      end

      @options.each do |opt|
        if opt.required_flag && (@values[opt.name] == opt.default || @values[opt.name].nil?)
          warn "Error: Missing required option: #{opt.long.empty? ? opt.short : opt.long}"
          exit 1
        end
      end
    end

    sig { params(name: Symbol).returns(T.untyped) }
    def get(name)
      @values[name]
    end

    # addメソッド（Optionオブジェクトを直接追加）
    sig { params(option: Option).returns(Option) }
    def add(option)
      @options << option
      option
    end

    private

    sig do
      params(
        name: Symbol, desc: String, short: String, long: String,
        required: T::Boolean, default: T.untyped, type: Symbol
      ).returns(Option)
    end
    def add_internal(name, desc, short, long, required, default, type: :string)
      opt = Option.new(name, desc: desc, short: short, long: long, required: required, default: default, type: type)
      @options << opt
      opt
    end
  end
end
