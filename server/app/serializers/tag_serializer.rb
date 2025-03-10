class TagSerializer < ActiveModel::Serializer
  attributes :id, :name, :votes_up, :votes_down, :user_vote, :created_at
  belongs_to :user, serializer: UserSerializer
  
  def votes_up
    object.vote_counts[:up]
  end

  def votes_down
    object.vote_counts[:down]
  end

  def user_vote
    scope ? object.user_vote(scope.id) : nil
  end
end