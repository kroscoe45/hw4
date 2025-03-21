class PlaylistSerializer < ActiveModel::Serializer
  attributes :id, :title, :is_public, :created_at, :updated_at, :tracks, :tags
  
  belongs_to :owner, serializer: UserSerializer
  
  def tracks
    object.full_tracks.map do |track|
      {
        id: track.id,
        title: track.title,
        artist: track.artist,
        added_at: track.added_at
      }
    end
  end
  
  def tags
    object.full_tags.map do |tag|
      TagSerializer.new(tag, scope: scope).as_json
    end
  end
  
  def owner
    object.owner
  end
end