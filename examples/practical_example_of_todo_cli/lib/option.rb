# frozen_string_literal: true
# typed: strict

require 'sorbet-runtime'

module SimpleOptions
  class Option
    extend T::Sig

    sig { returns(Symbol) }
    attr_reader :name

    sig { returns(String) }
    attr_reader :short, :long, :desc

    sig { returns(T::Boolean) }
    attr_reader :required_flag

    sig { returns(T.untyped) }
    attr_reader :default

    sig { returns(Symbol) }
    attr_reader :type

    BOOLEAN_MAP = T.let({
      'true' => true, 't' => true, '1' => true, 'yes' => true, 'y' => true,
      'false' => false, 'f' => false, '0' => false, 'no' => false, 'n' => false
    }.freeze, T::Hash[String, T::Boolean])

    sig do
      params(
        name: Symbol,
        desc: String,
        short: String,
        long: String,
        required: T::Boolean,
        default: T.untyped,
        type: Symbol,
        options: T.untyped
      ).void
    end
    def initialize(name, desc:, short: '', long: '', required: false, default: nil, type: :string, **options)
      @name = name
      @desc = desc
      @required_flag = required
      @default = default
      @type = type

      # short/longが両方空の場合、-nameを使用
      if short.empty? && long.empty?
        @short = "-#{name}"
        @long = ''
      else
        @short = short
        @long = long
      end

      validate_structure!

      # バリデーション用Procの配列
      @validators = T.let([], T::Array[T.proc.params(arg0: String).returns(T.nilable(String))])

      # 型に基づいたデフォルトのバリデーションを追加
      setup_default_validators

      # カスタムバリデーターの取り込み
      raw_validators = options[:validate]
      if raw_validators.is_a?(Proc)
        @validators << raw_validators
      elsif raw_validators.is_a?(Array)
        raw_validators.each { |v| @validators << v if v.is_a?(Proc) }
      end

      # 変換用Proc
      @converter = T.let(
        options[:convert] || ->(v) { convert_by_type(v) },
        T.proc.params(arg0: String).returns(T.untyped)
      )
    end

    # 実行時にバリデーションと変換をまとめて行う
    sig { params(value: T.nilable(String)).returns(T.untyped) }
    def process(value)
      return @default if value.nil?

      # 1. バリデーションの実行
      @validators.each do |v|
        msg = v.call(value)
        next if msg.nil?

        flags = [@short, @long].reject(&:empty?)
        flags_part = flags.empty? ? "option '#{@name}'" : "#{flags.join(' or ')} option"
        raise ArgumentError, "Validation failed: #{msg} for #{flags_part}"
      end

      # 2. 変換の実行
      @converter.call(value)
    end

    # ビルダーパターン用メソッド
    sig { params(block: T.proc.params(arg0: String).returns(T.nilable(String))).returns(T.self_type) }
    def validate(&block)
      @validators << block
      self
    end

    private

    sig { void }
    def setup_default_validators
      case @type
      when :integer
        @validators << ->(v) { v.match?(/\A-?\d+\z/) ? nil : 'must be an integer' }
      when :number
        @validators << ->(v) { v.match?(/\A-?\d+(\.\d+)?\z/) ? nil : 'must be a number' }
      end
    end

    sig { params(value: String).returns(T.untyped) }
    def convert_by_type(value)
      case @type
      when :integer then value.to_i
      when :number  then smart_number(value)
      when :boolean then BOOLEAN_MAP.fetch(value.downcase, true)
      else value.to_s
      end
    end

    sig { params(value: String).returns(T.any(Integer, Float, String)) }
    def smart_number(value)
      num = Float(value)
      (num % 1).zero? ? num.to_i : num
    rescue ArgumentError, TypeError
      @default || value
    end

    sig { void }
    def validate_structure!
      raise ArgumentError, "Property 'name' and 'desc' cannot be empty." if @name.to_s.empty? || @desc.empty?
      return unless @short.empty? && @long.empty?

      raise ArgumentError, "At least one of 'short' or 'long' flags must be provided for option '#{@name}'."
    end
  end
end
