class User < ApplicationRecord
  has_many :playlists, foreign_key: :owner_id, dependent: :destroy
  
  validates :auth0_id, presence: true, uniqueness: true
  validates :username, uniqueness: true, allow_nil: true,
            format: { with: /\A[A-Za-z0-9_-]{1,16}\z/, message: "only allows letters, numbers, hyphens and underscores" },
            length: { maximum: 16 }
  validates :roles, presence: true, inclusion: { in: ['user', 'admin'] }
  
  def admin?
    roles == 'admin'
  end
  
  def profile_completed?
    username.present?
  end
  
  def owns?(resource)
    return false unless resource.respond_to?(:owner_id)
    # Compare IDs directly as integers
    resource.owner_id == id
  end
end