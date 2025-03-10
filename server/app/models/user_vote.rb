class UserVote < ApplicationRecord
  belongs_to :user
  belongs_to :tag
  
  validates :vote_type, inclusion: { in: ['up', 'down'] }
  validates :user_id, uniqueness: { scope: :tag_id }
  
  # Set or update a user's vote for a tag
  def self.vote(user_id, tag_id, vote_type)
    # Ensure IDs are integers
    user_id = user_id.to_i
    tag_id = tag_id.to_i
    
    return false unless ['up', 'down', nil].include?(vote_type)
    
    # If vote_type is nil, remove the vote
    if vote_type.nil?
      vote = find_by(user_id: user_id, tag_id: tag_id)
      vote&.destroy
      return true
    end
    
    # Otherwise, create or update the vote
    vote = find_or_initialize_by(user_id: user_id, tag_id: tag_id)
    vote.vote_type = vote_type
    vote.save
  end
end