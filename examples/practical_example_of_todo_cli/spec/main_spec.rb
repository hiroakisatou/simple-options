# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require_relative '../main'
require_relative '../core/todo'
require_relative '../presentation/cli_parser'
require_relative '../presentation/cli_options'

RSpec.describe Main do
  let(:tempfile) { Tempfile.new(['test_todo', '.json']) }
  let(:original_argv) { ARGV.dup }

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  before do
    ENV['TODO_FILENAME'] = tempfile.path
  end

  after do
    ARGV.replace(original_argv)
    tempfile.close
    tempfile.unlink
  end

  describe 'integration tests' do
    context 'with -a option' do
      it 'adds a new task and saves to file' do
        ARGV.replace(['-a', 'New Task'])

        main = Main.new
        expect { main.main }.not_to raise_error

        todo = TodoList.new
        todo.get(tempfile.path)
        expect(todo.list.length).to eq(1)
        expect(todo.list[0].task).to eq('New Task')
      end
    end

    context 'with -l option' do
      it 'lists all tasks with proper formatting' do
        # Add tasks first
        todo = TodoList.new
        todo.add('Task 1')
        todo.add('Task 2')
        todo.add('Task 3')
        todo.complete(2)
        todo.save(tempfile.path)

        ARGV.replace(['-l'])

        main = Main.new
        output = nil
        expect { output = capture_stdout { main.main } }.not_to raise_error

        # Check that all tasks are displayed
        expect(output).to include('Task 1')
        expect(output).to include('Task 2')
        expect(output).to include('Task 3')

        # Check formatting: incomplete tasks have space prefix, completed have X
        expect(output).to match(/  1: Task 1/)
        expect(output).to match(/X 2: Task 2/)
        expect(output).to match(/  3: Task 3/)

        # Check that output has multiple lines
        lines = output.split("\n")
        expect(lines.length).to eq(3)
      end
    end

    context 'with -c option' do
      it 'completes a task' do
        # Add a task first
        todo = TodoList.new
        todo.add('Task to complete')
        todo.save(tempfile.path)

        ARGV.replace(['-c', '1'])

        main = Main.new
        expect { main.main }.not_to raise_error

        todo2 = TodoList.new
        todo2.get(tempfile.path)
        expect(todo2.list[0].done).to be true
      end
    end

    context 'with -d option' do
      it 'deletes a task' do
        # Add tasks first
        todo = TodoList.new
        todo.add('Task 1')
        todo.add('Task 2')
        todo.save(tempfile.path)

        ARGV.replace(['-d', '1'])

        main = Main.new
        expect { main.main }.not_to raise_error

        todo2 = TodoList.new
        todo2.get(tempfile.path)
        expect(todo2.list.length).to eq(1)
        expect(todo2.list[0].task).to eq('Task 2')
      end
    end

    context 'with invalid index' do
      it 'exits with error message' do
        ARGV.replace(['-c', '999'])

        main = Main.new
        expect { main.main }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context 'with multiple options' do
      it 'exits with error message' do
        ARGV.replace(['-a', 'Task', '-l'])

        main = Main.new
        expect { main.main }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context 'with no file existing' do
      it 'creates new file on first add' do
        FileUtils.rm_f(tempfile.path)

        ARGV.replace(['-a', 'First Task'])

        main = Main.new
        expect { main.main }.not_to raise_error
        expect(File.exist?(tempfile.path)).to be true
      end
    end
  end
end
