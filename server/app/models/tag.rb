class Tag < ApplicationRecord
  belongs_to :playlist
  belongs_to :user
  has_many :user_votes, dependent: :destroy
  
  validates :name, presence: true, length: { minimum: 2, maximum: 20 }
  before_save :downcase_name
  
  scope :by_playlist, ->(playlist_id) { where(playlist_id: playlist_id) }
  scope :by_name, ->(name) { where("name ILIKE ?", name) }
  scope :alphabetical, -> { order(name: :asc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { 
    left_joins(:user_votes)
    .where(user_votes: { vote_type: 'up' })
    .group(:id)
    .order(Arel.sql('COUNT(user_votes.id) DESC'))
  }
  
  def downcase_name   
    self.name = name.downcase.strip if name.present?
  end
  
  def vote_counts
    up_votes = user_votes.where(vote_type: 'up').count
    down_votes = user_votes.where(vote_type: 'down').count
    { up: up_votes, down: down_votes }
  end
  
  def user_vote(user_id)
    vote = user_votes.find_by(user_id: user_id)
    vote&.vote_type
  end
  
  # Add a vote from a user for this tag
  def add_vote(user_id, playlist_id, vote_type)
    # Map 'none' to nil for the UserVote.vote method
    vote_value = vote_type == 'none' ? nil : vote_type
    UserVote.vote(user_id, id, vote_value)
  end
  
  # Get all playlists this tag is attached to
  def self.find_playlists_with_tag_name(name)
    joins(:playlist)
      .where("tags.name ILIKE ?", name)
      .select("DISTINCT ON (playlists.id) playlists.*")
  end
  
  # Find tags in specified order
  def self.find_in_order(ids)
    return [] if ids.blank?
    
    # Ensure all IDs are integers
    integer_ids = ids.map(&:to_i)
    
    # Find tags with the given IDs
    tags = where(id: integer_ids).index_by(&:id)
    
    # Return tags in the same order as the ids array
    integer_ids.map { |id| tags[id] }.compact
  end
end