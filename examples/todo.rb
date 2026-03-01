#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/simple-cli-options'

# Todoリスト管理ツールのサンプル
parser = SimpleOptions::Options.new(
  program_name: 'todo',
  description: 'A simple todo list manager'
)

# オプションを定義（名前とdescのみ指定）
parser.boolean(:list, desc: 'Show list of todos')
parser.string(:add, desc: 'Add a new todo item')
parser.integer(:delete, desc: 'Delete todo by ID')
parser.boolean(:complete, desc: 'Mark todo as complete')
parser.integer(:id, desc: 'Todo ID for complete operation')

# コマンドライン引数をパース
parser.parse

# 簡易的なTodoストレージ（実際のアプリではファイルやDBを使用）
TODOS = [
  { id: 1, text: 'Buy groceries', completed: false },
  { id: 2, text: 'Write documentation', completed: false },
  { id: 3, text: 'Review pull requests', completed: true }
]

# コマンドを実行
if parser.get(:list)
  puts "\n📝 Todo List:"
  puts "=" * 50
  TODOS.each do |todo|
    status = todo[:completed] ? '✓' : ' '
    puts "  [#{status}] #{todo[:id]}. #{todo[:text]}"
  end
  puts "=" * 50
  puts "\nTotal: #{TODOS.size} items (#{TODOS.count { |t| t[:completed] }} completed)"

elsif parser.get(:add)
  new_todo = parser.get(:add)
  puts "✅ Added: '#{new_todo}'"
  puts "   (In a real app, this would be saved to storage)"

elsif parser.get(:delete)
  id = parser.get(:delete)
  puts "🗑️  Deleted todo ##{id}"
  puts "   (In a real app, this would remove from storage)"

elsif parser.get(:complete) && parser.get(:id)
  id = parser.get(:id)
  puts "✓ Marked todo ##{id} as complete"
  puts "   (In a real app, this would update storage)"

else
  puts "No action specified. Use -h for help."
end
