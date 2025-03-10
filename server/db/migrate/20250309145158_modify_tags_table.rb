class ModifyTagsTable < ActiveRecord::Migration[8.0]
  def up
    # First, remove check constraint and unique index on name
    execute "ALTER TABLE tags DROP CONSTRAINT IF EXISTS check_tag_name_length"
    remove_index :tags, :name, if_exists: true
    
    # Add columns for the new associations
    add_reference :tags, :playlist, null: false, foreign_key: true
    add_reference :tags, :user, null: false, foreign_key: true
    
    # Keep name validation but allow duplicates
    execute "ALTER TABLE tags ADD CONSTRAINT check_tag_name_length CHECK (char_length(name) BETWEEN 2 AND 20)"
    
    # Remove attached_to column which is no longer needed
    remove_column :tags, :attached_to, if_exists: true
  end
  
  def down
    # This would be complex to roll back if there's data
    # Here's a simplified version that doesn't attempt data migration
    add_column :tags, :attached_to, :jsonb, null: false, default: '{}'
    add_index :tags, :attached_to, using: 'gin'
    
    remove_reference :tags, :playlist
    remove_reference :tags, :user
    
    add_index :tags, :name, unique: true
  end
end