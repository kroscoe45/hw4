class CreatePlaylists < ActiveRecord::Migration[8.0]
  def change
    create_table :playlists do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.boolean :is_public, null: false, default: false
      t.string :tracks, array: true, default: []
      t.string :tags, array: true, default: []

      t.timestamps
    end
    add_index :playlists, :is_public
    add_index :playlists, :tracks, using: 'gin'
    add_index :playlists, :tags, using: 'gin'
  end
end