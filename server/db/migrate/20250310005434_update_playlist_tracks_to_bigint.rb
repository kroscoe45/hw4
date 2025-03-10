class UpdatePlaylistTracksToBigint < ActiveRecord::Migration[8.0]
  def up
    # Create a temporary column of type bigint array
    add_column :playlists, :tracks_bigint, :bigint, array: true, default: []
    
    # Copy data from string array to bigint array with conversion
    execute <<-SQL
      UPDATE playlists
      SET tracks_bigint = ARRAY(
        SELECT NULLIF(track::bigint, 0)
        FROM unnest(tracks) AS track
        WHERE track ~ '^[0-9]+$'
      )
    SQL
    # Remove the old column and rename the new one
    remove_column :playlists, :tracks
    rename_column :playlists, :tracks_bigint, :tracks
    
    # Add index on the new column
    add_index :playlists, :tracks, using: :gin
  end
  
  def down
    # Create a temporary column of type string array
    add_column :playlists, :tracks_string, :string, array: true, default: []
    
    # Copy data from bigint array to string array with conversion
    execute <<-SQL
      UPDATE playlists
      SET tracks_string = ARRAY(
        SELECT track::text
        FROM unnest(tracks) AS track
      )
    SQL
    
    # Remove the bigint column and rename the string one
    remove_column :playlists, :tracks
    rename_column :playlists, :tracks_string, :tracks
    
    # Add index on the new column
    add_index :playlists, :tracks, using: :gin
  end
end