# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require 'stringio'

# ==========================================
# 1. Option クラス（各フラグの定義と検証・変換）
# ==========================================
class Option
  extend T::Sig

  sig { returns(Symbol) }
  attr_reader :name

  sig { returns(String) }
  attr_reader :short, :long, :desc

  sig { returns(T::Boolean) }
  attr_reader :required_flag

  sig do
    params(
      name: Symbol,
      short: String,
      long: String,
      desc: String,
      required: T::Boolean,
      options: T.untyped
    ).void
  end
  def initialize(name, short:, long:, desc:, required: false, **options)
    @name = name
    @short = short
    @long = long
    @desc = desc
    @required_flag = required

    validate_structure!

    # バリデーションは追加(Array)可能、変換は上書き
    @validators = T.let([options[:validate]].compact, T::Array[T.proc.params(arg0: String).returns(T::Boolean)])
    @converter  = T.let(options[:convert] || ->(v) { v }, T.proc.params(arg0: String).returns(T.untyped))
  end

  sig { params(block: T.proc.params(arg0: String).returns(T::Boolean)).returns(T.self_type) }
  def validate(&block)
    @validators << block
    self
  end

  sig { params(block: T.proc.params(arg0: String).returns(T.untyped)).returns(T.self_type) }
  def convert(&block)
    @converter = block
    self
  end

  sig { params(value: String).returns(T.untyped) }
  def process(value)
    @validators.each do |v|
      raise "Validation failed for option '#{@name}' with value: #{value}" unless v.call(value)
    end
    @converter.call(value)
  end

  private

  sig { void }
  def validate_structure!
    raise ArgumentError, "Property 'name' and 'desc' cannot be empty." if @name.to_s.empty? || @desc.empty?

    return unless @short.empty? && @long.empty?

    raise ArgumentError, "At least one of 'short' or 'long' flags must be provided for option '#{@name}'."
  end
end
