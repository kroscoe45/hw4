class Playlist < ApplicationRecord
  include Paginatable

  belongs_to :owner, class_name: 'User'
  
  validates :title, presence: true
  validate :validate_track_ids
  validate :validate_tag_ids

  # Ensure arrays are always returned, even if NULL in database
  def tracks
    self[:tracks] || []
  end
  
  def tags
    self[:tags] || []
  end
  
  # Add a track to the playlist
  # Always adds to the end of the list
  def add_track(track_id)
    track_id = track_id.to_s
    
    # Only add if not already in the playlist and track exists
    unless tracks.include?(track_id)
      # Verify track exists
      Track.find(track_id)
      
      # Add to array
      self.tracks = tracks + [track_id]
      save
    else
      true # Return success if track was already there
    end
  rescue ActiveRecord::RecordNotFound
    errors.add(:tracks, "Track with ID #{track_id} not found")
    false
  end
  
  # Remove a track from the playlist
  def remove_track(track_id)
    track_id = track_id.to_s
    
    if tracks.include?(track_id)
      self.tracks = tracks - [track_id]
      save
    else
      true # Return success if track wasn't in the list
    end
  end
  
  # Update the entire track list (for reordering)
  def update_track_list(track_ids)
    # doing this in the playlist api instead
    # Ensure all IDs are valid
    # track_ids = track_ids.map(&:to_s)
    
    # Validate all tracks exist
    # is this optimal? idk if this does multiple queries or just one
    existing_tracks = Track.where(id: track_ids).pluck(:id).map(&:to_s)
    missing_tracks = track_ids - existing_tracks
    
    if missing_tracks.any?
      errors.add(:tracks, "Tracks with IDs #{missing_tracks.join(', ')} not found")
      return false
    end
    
    # update playlist
    self.tracks = track_ids
    save
  end
  
def self.filter_by_params(params, user = nil)
  playlists = if params[:owner_id].present?
    by_owner(params[:owner_id])
  elsif params[:tag_id].present?
    with_tag(params[:tag_id])
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

  # Add a tag to the playlist with transaction safety
  def add_tag(tag_id, user_id)
    tag_id = tag_id.to_s
    user_id = user_id.to_s
    
    # Only add if not already in the playlist
    return true if tags.include?(tag_id)
    
    # Use transaction to ensure data consistency
    transaction do
      # Verify tag exists
      tag = Tag.find(tag_id)
      
      # Add to array
      self.tags = tags + [tag_id]
      
      # Update the tag's attached_to field
      attached_data = tag.attached_to || {}
      attached_data[id.to_s] = { 
        "voteUp" => [],
        "voteDown" => [],
        "suggestedBy" => user_id
      }
      
      # Save both records
      tag.update!(attached_to: attached_data)
      save!
    end
    true
  end
  rescue ActiveRecord::RecordNotFound
    errors.add(:tags, "Tag with ID #{tag_id} not found")
    false
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, "Failed to add tag: #{e.message}")
    false

  # Remove a tag from the playlist with transaction safety
  def remove_tag(tag_id)
    tag_id = tag_id.to_s
    
    # Only remove if in the playlist
    return true unless tags.include?(tag_id)
    
    # Use transaction to ensure data consistency
    transaction do
      # Verify tag exists
      tag = Tag.find(tag_id)
      
      # Remove from array
      self.tags = tags - [tag_id]
      
      # Update the tag's attached_to field
      attached_data = tag.attached_to || {}
      attached_data.delete(id.to_s)
      
      # Save both records
      tag.update!(attached_to: attached_data)
      save!
    end
    true
  end
  rescue ActiveRecord::RecordNotFound
    # If tag doesn't exist, just remove it from our array
    self.tags = tags - [tag_id]
    save
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, "Failed to remove tag: #{e.message}")
    false
  
  # Get all tracks as full objects in playlist order
  def full_tracks
    Track.find_in_order(tracks)
  end
  
  # Get all tags as full objects in order they were added
  def full_tags
    Tag.find_in_order(tags)
  end
  
  # Scopes for common queries
  scope :public_playlists, -> { where(is_public: true) }
  scope :by_owner, ->(owner_id) { where(owner_id: owner_id) }
  scope :with_tag, ->(tag_id) { where("? = ANY(tags)", tag_id.to_s) }
  scope :with_track, ->(track_id) { where("? = ANY(tracks)", track_id.to_s) }
  scop

  private
  
  # Validate that all track IDs reference existing tracks
  def validate_track_ids
    return if tracks.blank?
    
    existing_tracks = Track.where(id: tracks).pluck(:id).map(&:to_s)
    missing_tracks = tracks - existing_tracks
    
    if missing_tracks.any?
      errors.add(:tracks, "Tracks with IDs #{missing_tracks.join(', ')} not found")
    end
  end
  
  # Validate that all tag IDs reference existing tags
  def validate_tag_ids
    return if tags.blank?
    
    existing_tags = Tag.where(id: tags).pluck(:id).map(&:to_s)
    missing_tags = tags - existing_tags
    
    if missing_tags.any?
      errors.add(:tags, "Tags with IDs #{missing_tags.join(', ')} not found")
    end
  end
end