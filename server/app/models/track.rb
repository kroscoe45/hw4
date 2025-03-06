class Track < ApplicationRecord
    validates :title, presence: true
    validates :artist, presence: true
    
    # Scopes for common queries
    scope :by_artist, ->(artist) { where("artist ILIKE ?", artist) }
    scope :search_title, ->(term) { where("title ILIKE ?", "%#{term}%") }
    scope :recent, -> { order(added_at: :desc) }
    scope :alphabetical, -> { order(title: :asc) }
    
    # Find tracks by IDs in a specific order (optimized)
    def self.find_in_order(ids)
      return [] if ids.blank?
      
      # Convert string IDs to integers if needed
      integer_ids = ids.map(&:to_i)
      
      # Find all tracks with the given IDs
      tracks = where(id: integer_ids).index_by(&:id)
      
      # Return tracks in the same order as the ids array
      integer_ids.map { |id| tracks[id] }.compact
    end
    
    # Always set added_at to the current time on creation
    before_create :set_added_at
    
    private
    
    def set_added_at
      self.added_at = Time.current
    end
  end