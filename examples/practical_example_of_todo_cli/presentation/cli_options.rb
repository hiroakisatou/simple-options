# frozen_string_literal: true

require 'sorbet-runtime'

# this class contain CLI options parse result
class CliOptions < T::Struct
  extend T::Sig

  prop :add, T.nilable(String)
  prop :complete, T.nilable(Integer)
  prop :delete, T.nilable(Integer)
  prop :list, T.nilable(T::Boolean)

  sig { returns(T::Boolean) }
  def valid?
    non_nil_count = [add, complete, delete, list].count { |v| !v.nil? }
    non_nil_count == 1
  end

  sig { returns(T.nilable(Symbol)) }
  def active_option
    return :add unless add.nil?
    return :complete unless complete.nil?
    return :delete unless delete.nil?
    return :list unless list.nil?

    nil
  end
end
