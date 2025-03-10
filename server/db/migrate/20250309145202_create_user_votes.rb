class CreateUserVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :user_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.string :vote_type, null: false
      
      t.timestamps
    end
    
    add_index :user_votes, [:user_id, :tag_id], unique: true
    
    execute <<-SQL
      ALTER TABLE user_votes
      ADD CONSTRAINT check_vote_type
      CHECK (vote_type IN ('up', 'down'));
    SQL
  end
end