require_relative 'todo_searchable'

class Todo < ApplicationRecord
  include TodoSearchable
end
