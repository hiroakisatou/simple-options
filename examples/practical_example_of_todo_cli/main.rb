# frozen_string_literal: true

require 'sorbet-runtime'

require_relative 'presentation/cli_parser'
require_relative 'core/todo'
require_relative 'error'

# main mediator class of workflow
class Main
  extend T::Sig

  sig { void }
  def initialize
    @todo = TodoList.new
  end

  sig { void }
  def main
    set_filename
    parse_options
    load_data
    switch_by_option
  end

  private

  sig { void }
  def set_filename
    @filename = ENV['TODO_FILENAME'] || '.todo.json'
  end

  sig { void }
  def load_data
    @todo.get(@filename)
  rescue StandardError => e
    warn e.message
    exit 1
  end

  sig { void }
  def parse_options
    parser = CliParser.new
    @options = parser.parse
    raise ParseError, 'Select one option only' unless @options.valid?
  rescue ParseError => e
    warn e.message
    exit 1
  end

  sig { void }
  def switch_by_option
    case @options.active_option
    when :add
      @todo.add(@options.add)
      @todo.save(@filename)
    when :complete
      @todo.complete(@options.complete)
      @todo.save(@filename)
    when :delete
      @todo.delete(@options.delete)
      @todo.save(@filename)
    when :list
      puts @todo
    end
  rescue IndexError => e
    warn e.message
    exit 1
  rescue IOError, SystemCallError => e
    warn "Failed to save file: #{e.message}"
    exit 1
  end
end

Main.new.main if __FILE__ == $PROGRAM_NAME
