class AddTodos < ActiveRecord::Migration[5.2]
  def change
    create_table :todos do |t|
      t.string :todo
      t.boolean :completed
      t.datetime :created_at
      t.datetime :updated_at
      t.float    :cost
      t.integer  :repeat_days
    end
  end
end
