# frozen_string_literal: true

require 'sorbet-runtime'
require_relative 'item'
require 'json'

# TodoList implements main logic of todo list
class TodoList
  extend T::Sig

  sig { returns(T::Array[Item]) }
  attr_reader :list

  sig { void }
  def initialize
    @list = []
  end

  sig { params(task: String).void }
  def add(task)
    @list << Item.new(
      task: task,
      done: false,
      created_at: Time.now,
      completed_at: nil
    )
  end

  sig { params(index: Integer).void }
  def complete(index)
    if index < 1 || index > @list.size
      raise IndexError, "Index out of range"
    end

    # index user show is 1-based, but @list is 0-based
    item = @list[index - 1]
    @list[index - 1] = Item.new(
      task: item.task,
      done: true,
      created_at: item.created_at,
      completed_at: Time.now
    )
  end

  sig { params(index: Integer).void }
  def delete(index)
    if index < 1 || index > @list.size
      raise IndexError, "Index out of range"
    end

    @list.delete_at(index - 1)
  end

  sig { params(filename: String).void }
  def save(filename)
    data = @list.map do |item|
      {
        task: item.task,
        done: item.done,
        created_at: item.created_at.iso8601,
        completed_at: item.completed_at&.iso8601
      }
    end
    File.write(filename, JSON.generate(data))
  end

  sig { params(filename: String).void }
  def get(filename)
    unless File.exist?(filename)
      return
    end

    content = File.read(filename)
    return if content.empty?

    data = JSON.parse(content)
    @list = data.map do |item_hash|
      completed = item_hash['completed_at']
      Item.new(
        task: item_hash['task'],
        done: item_hash['done'],
        created_at: Time.parse(item_hash['created_at']),
        completed_at: completed.nil? ? nil : Time.parse(completed)
      )
    end
  end

  sig { returns(String) }
  def to_s
    formatted = String.new
    @list.each_with_index do |item, index|
      prefix = item.done ? "X" : " "
      formatted << "#{prefix} #{index + 1}: #{item.task}\n"
    end
    return formatted
  end
end
