class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.jsonb :attached_to, null: false, default: '{}'

      t.timestamps
    end
    add_index :tags, :name, unique: true
    add_index :tags, :attached_to, using: 'gin'
    
    execute "ALTER TABLE tags ADD CONSTRAINT check_tag_name_length CHECK (char_length(name) BETWEEN 2 AND 20)"
  end
end