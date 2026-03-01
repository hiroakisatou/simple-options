# frozen_string_literal: true

require 'sorbet-runtime'
require_relative 'cli_options'
require_relative '../lib/options'
# this class parse CLI options
class CliParser
  extend T::Sig

  sig { void }
  def initialize
    @parser = SimpleOptions::Options.new(program_name: 'todo', description: 'Simple todo list')
    set_options
  end

  sig { void }
  def set_options
    @parser.string(:add, desc: 'Add a new todo by task name', short: '-a', long: '--add')
    @parser.integer(:complete, desc: 'Complete a todo with index number', short: '-c', long: '--complete')
    @parser.integer(:delete, desc: 'Delete a todo with index number', short: '-d', long: '--delete')
    @parser.boolean(:list, desc: 'List all todos', short: '-l', long: '--list')
  end

  sig { returns(CliOptions) }
  def parse
    @parser.parse

    add_val = @parser.get(:add)
    add_val = nil if add_val.nil? || add_val == ''

    complete_val = @parser.get(:complete)
    complete_val = nil if complete_val.nil? || complete_val == 0

    delete_val = @parser.get(:delete)
    delete_val = nil if delete_val.nil? || delete_val == 0

    list_val = @parser.get(:list)
    list_val = nil if list_val == false

    return CliOptions.new(
      add: add_val,
      complete: complete_val,
      delete: delete_val,
      list: list_val
    )
  end
end
