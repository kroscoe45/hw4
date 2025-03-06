class CreateTracks < ActiveRecord::Migration[8.0]
  def change
    create_table :tracks do |t|
      t.string :title, null: false
      t.string :artist, null: false
      t.datetime :added_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end
    add_index :tracks, :artist
    add_index :tracks, :title
    add_index :tracks, [:artist, :title], unique: true
    
    # Create composite index for faster searching
    add_index :tracks, "lower(title) varchar_pattern_ops", name: 'index_tracks_on_lowercase_title'
    add_index :tracks, "lower(artist) varchar_pattern_ops", name: 'index_tracks_on_lowercase_artist'
  end
end