class CreateInitialSchema < ActiveRecord::Migration[8.0]
  def change
    create_table :initial_schemas do |t|
      t.timestamps
    end
  end
end
