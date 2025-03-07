class Track < ApplicationRecord
    validates :title, presence: true
    validates :artist, presence: true
    
    # Scopes for common queries
    scope :by_artist, ->(artist) { where("artist ILIKE ?", artist) }
    scope :search_title, ->(term) { where("title ILIKE ?", "%#{term}%") }
    
    # Find tracks by IDs in a specific order (optimized)
    def self.find_in_order(ids)
      return [] if ids.blank?
      
      # Convert string IDs to integers if needed
      # integer_ids = ids.map(&:to_i)
      # just do this earlier and let's just say it needs to be an int
      # before this is called
      
      # find tracks with the given IDs
      tracks = where(id: ids).index_by(&:id)
      
      # return tracks in the same order as the ids array
      integer_ids.map { |id| tracks[id] }.compact
    end
    
    # always set added_at to the current time on creation
    before_create :set_added_at
    private
    
    def set_added_at
      self.added_at = Time.current
    end
  end