# frozen_string_literal: true

require 'sorbet-runtime'

# Item represents a single todo item
class Item < T::Struct
  const :task, String
  const :done, T::Boolean
  const :created_at, Time
  const :completed_at, T.nilable(Time)
end
