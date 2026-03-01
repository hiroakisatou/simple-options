# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require_relative '../core/todo'
require_relative '../core/item'

RSpec.describe TodoList do
  describe '#add' do
    it 'adds a new task to the list' do
      list = TodoList.new
      task_name = 'New Task'

      list.add(task_name)

      expect(list.list[0].task).to eq(task_name)
    end
  end

  describe '#complete' do
    it 'marks a task as completed' do
      list = TodoList.new
      task_name = 'New Task'

      list.add(task_name)

      expect(list.list[0].task).to eq(task_name)
      expect(list.list[0].done).to be false

      list.complete(1)

      expect(list.list[0].done).to be true
      expect(list.list[0].completed_at).not_to be_nil
    end

    it 'raises IndexError when index is out of range' do
      list = TodoList.new

      expect { list.complete(1) }.to raise_error(IndexError, 'Index out of range')
    end
  end

  describe '#delete' do
    it 'deletes a task from the list' do
      list = TodoList.new
      tasks = [
        'New Task 1',
        'New Task 2',
        'New Task 3'
      ]

      tasks.each { |task| list.add(task) }

      expect(list.list[0].task).to eq(tasks[0])

      list.delete(2)

      expect(list.list.length).to eq(2)
      expect(list.list[1].task).to eq(tasks[2])
    end

    it 'raises IndexError when index is out of range' do
      list = TodoList.new

      expect { list.delete(1) }.to raise_error(IndexError, 'Index out of range')
    end
  end

  describe '#save and #get' do
    it 'saves and retrieves the list from a file' do
      list1 = TodoList.new
      list2 = TodoList.new
      task_name = 'New Task'

      list1.add(task_name)

      expect(list1.list[0].task).to eq(task_name)

      tempfile = Tempfile.new(['todo', '.json'])

      begin
        list1.save(tempfile.path)
        list2.get(tempfile.path)

        expect(list2.list[0].task).to eq(list1.list[0].task)
      ensure
        tempfile.close
        tempfile.unlink
      end
    end
  end

  describe '#to_s' do
    it 'formats the list as a string' do
      list = TodoList.new

      list.add('Task 1')
      list.add('Task 2')
      list.complete(1)

      output = list.to_s

      expect(output).to include('X 1: Task 1')
      expect(output).to include('  2: Task 2')
    end

    it 'returns empty string for empty list' do
      list = TodoList.new

      expect(list.to_s).to eq('')
    end
  end
end
