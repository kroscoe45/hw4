class PlaylistSerializer < ActiveModel::Serializer
  attributes :id, :title, :is_public, :created_at, :updated_at
  
  belongs_to :owner, serializer: UserSerializer
  
  def owner
    object.user
  end
end