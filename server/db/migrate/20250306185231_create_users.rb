class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :auth0_id, null: false
      t.string :roles, null: false, default: 'user'
      t.string :username, null: true, limit: 16

      t.timestamps
    end
    add_index :users, :auth0_id, unique: true
    add_index :users, :username, unique: true, where: "username IS NOT NULL"
    
    execute <<-SQL
      ALTER TABLE users 
      ADD CONSTRAINT check_username_format 
      CHECK (username IS NULL OR username ~ '^[A-Za-z0-9_-]{1,16}$');
    SQL
    
    execute <<-SQL
      ALTER TABLE users 
      ADD CONSTRAINT check_valid_roles 
      CHECK (roles IN ('user', 'admin'));
    SQL
  end
end