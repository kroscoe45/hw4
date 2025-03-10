class Playlist < ApplicationRecord
  include Paginatable

  belongs_to :owner, class_name: 'User'
  has_many :tags, dependent: :destroy
  
  validates :title, presence: true
  validate :validate_track_ids
  
  def tracks
    self[:tracks] || []
  end
  
  # Add a track to the playlist
  def add_track(track_id)
    # Ensure we're working with integers
    track_id = track_id.to_i
    
    # Don't add duplicates
    return false if tracks.include?(track_id)
    
    # Verify the track exists
    begin
      Track.find(track_id)
    rescue ActiveRecord::RecordNotFound
      errors.add(:tracks, "Track with ID #{track_id} not found")
      return false
    end
    
    # Add track and save
    self.tracks = tracks + [track_id]
    save
  end
  
  # Remove a track from the playlist
  def remove_track(track_id)
    # Ensure we're working with integers
    track_id = track_id.to_i
    
    # Check if track is in the playlist
    unless tracks.include?(track_id)
      errors.add(:tracks, "Track with ID #{track_id} not found in playlist")
      return false
    end
    
    # Remove track and save
    self.tracks = tracks - [track_id]
    save
  end
  
  # Update the entire track list
  def update_track_list(track_ids)
    # Ensure we're working with integers
    track_ids = track_ids.map(&:to_i)
    
    # Verify all tracks exist
    have_tracks = Track.where(id: track_ids).pluck(:id)
    missing_tracks = track_ids - have_tracks
    
    if missing_tracks.any?
      errors.add(:tracks, "Tracks with IDs #{missing_tracks.join(', ')} not found")
      return false
    end
    
    # Update tracks and save
    self.tracks = track_ids
    save
  end
  
  # Add a tag to the playlist
  def add_tag(name, user_id)
    tags.create(name: name, user_id: user_id)
  end
  
  # Remove a tag from the playlist
  def remove_tag(tag_id)
    tag = tags.find_by(id: tag_id)
    return false unless tag
    
    tag.destroy
    true
  end
  
  # Get all tags for this playlist
  def full_tags
    tags.includes(:user_votes, :user)
  end
  
  # Get paginated tags
  def paginated_tags(params)
    page = [params[:page].to_i, 1].max
    per_page = [[params[:per_page].to_i, 20].max, 100].min
    
    tags_relation = tags.includes(:user_votes, :user)
    
    # Apply optional sorting
    tags_relation = case params[:sort]
    when 'popular'
      tags_relation.popular
    when 'recent'
      tags_relation.recent
    when 'alphabetical'
      tags_relation.alphabetical
    else
      tags_relation
    end
    
    result = tags_relation.limit(per_page).offset((page - 1) * per_page)
    
    {
      records: result,
      meta: {
        total_count: tags_relation.count,
        current_page: page,
        per_page: per_page,
        total_pages: (tags_relation.count.to_f / per_page).ceil
      }
    }
  end
  
  # Class method to filter playlists by various parameters
  def self.filter_by_params(params, user = nil)
    playlists = if params[:owner_id].present?
      by_owner(params[:owner_id])
    elsif params[:tag_name].present?
      Tag.find_playlists_with_tag_name(params[:tag_name])
    elsif params[:track_id].present?
      with_track(params[:track_id])
    else
      all
    end
    
    # Filter for public playlists unless user is provided
    playlists = playlists.public_playlists unless user
    
    # Apply optional sorting
    playlists = playlists.recent if params[:sort] == 'recent'
    
    playlists
  end
  
  # Get all tracks as full objects in playlist order
  def full_tracks
    Track.find_in_order(tracks)
  end
  
  # Method to get paginated tracks
  def paginated_tracks(params)
    page = [params[:page].to_i, 1].max
    per_page = [[params[:per_page].to_i, 20].max, 100].min
    
    tracks_array = full_tracks
    offset = (page - 1) * per_page
    result = tracks_array[offset, per_page] || []
    
    {
      records: result,
      meta: {
        total_count: tracks_array.size,
        current_page: page,
        per_page: per_page,
        total_pages: (tracks_array.size.to_f / per_page).ceil
      }
    }
  end
  
  # Scopes for common queries
  scope :public_playlists, -> { where(is_public: true) }
  scope :by_owner, ->(owner_id) { where(owner_id: owner_id) }
  scope :with_track, ->(track_id) { where("? = ANY(tracks)", track_id) }
  scope :recent, -> { order(created_at: :desc) }

  private
  
  # Validate that all track IDs reference existing tracks
  def validate_track_ids
    return if tracks.blank?
    
    # Verify all track IDs exist in the database
    existing_tracks = Track.where(id: tracks).pluck(:id)
    missing_tracks = tracks - existing_tracks
    
    if missing_tracks.any?
      errors.add(:tracks, "Tracks with IDs #{missing_tracks.join(', ')} not found")
    end
  end
end