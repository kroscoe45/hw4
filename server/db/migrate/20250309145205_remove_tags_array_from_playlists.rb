class RemoveTagsArrayFromPlaylists < ActiveRecord::Migration[8.0]
  def change
    remove_index :playlists, :tags, if_exists: true
    remove_column :playlists, :tags, if_exists: true
  end
end