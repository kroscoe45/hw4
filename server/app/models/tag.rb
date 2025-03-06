class Tag < ApplicationRecord
    validates :name, presence: true, uniqueness: true, length: { minimum: 2, maximum: 20 }
    
    before_save :downcase_name
    
    def downcase_name
      self.name = name.downcase.strip if name.present?
    end
    
    # Find tags by IDs in a specific order
    def self.find_in_order(ids)
      return [] if ids.blank?
      
      # Convert string IDs to integers if needed
      integer_ids = ids.map(&:to_i)
      
      # Find all tags with the given IDs
      tags = where(id: integer_ids).index_by(&:id)
      
      # Return tags in the same order as the ids array
      integer_ids.map { |id| tags[id] }.compact
    end
    
    # Register a vote on a tag for a playlist
    def vote(playlist_id, user_id, vote_type)
      playlist_id = playlist_id.to_s
      user_id = user_id.to_s
      
      # Initialize the structure if needed
      self.attached_to ||= {}
      self.attached_to[playlist_id] ||= { "voteUp" => [], "voteDown" => [], "suggestedBy" => nil }
      
      # Remove user from both vote arrays to avoid duplicate votes
      self.attached_to[playlist_id]["voteUp"] = attached_to[playlist_id]["voteUp"].reject { |id| id == user_id }
      self.attached_to[playlist_id]["voteDown"] = attached_to[playlist_id]["voteDown"].reject { |id| id == user_id }
      
      # Add user to the appropriate vote array
      if vote_type == "up"
        self.attached_to[playlist_id]["voteUp"] << user_id
      elsif vote_type == "down"
        self.attached_to[playlist_id]["voteDown"] << user_id
      end
      
      save
    end
    
    # Get all playlists this tag is attached to
    def playlists
      return [] if attached_to.blank?
      
      playlist_ids = attached_to.keys
      Playlist.where(id: playlist_ids)
    end
    
    # Get vote counts for a specific playlist
    def vote_counts(playlist_id)
      playlist_id = playlist_id.to_s
      
      return { up: 0, down: 0 } unless attached_to && attached_to[playlist_id]
      
      {
        up: attached_to[playlist_id]["voteUp"].size,
        down: attached_to[playlist_id]["voteDown"].size
      }
    end
    
    # Check if a user has voted on this tag for a playlist
    def user_vote(playlist_id, user_id)
      playlist_id = playlist_id.to_s
      user_id = user_id.to_s
      
      return nil unless attached_to && attached_to[playlist_id]
      
      if attached_to[playlist_id]["voteUp"].include?(user_id)
        "up"
      elsif attached_to[playlist_id]["voteDown"].include?(user_id)
        "down"
      else
        nil
      end
    end
    
    # Get the user who suggested this tag for a playlist
    def suggested_by(playlist_id)
      playlist_id = playlist_id.to_s
      
      return nil unless attached_to && attached_to[playlist_id]
      
      attached_to[playlist_id]["suggestedBy"]
    end
  end