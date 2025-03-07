class Api::TagsController < ApplicationController
  before_action :authenticate_request!, except: [:index, :show]
  before_action :set_tag, only: [:show, :vote]
  
  # GET /api/tags
  def index
    @tags = if params[:playlist_id].present?
      Tag.for_playlist(params[:playlist_id])
    else
      Tag.all
    end
    
    # Apply optional sorting
    @tags = case params[:sort]
    when 'popular'
      @tags.popular
    when 'recent'
      @tags.recent
    when 'alphabetical'
      @tags.alphabetical
    else
      @tags
    end
    
    # Apply pagination (default: 20 per page)
    page = [params[:page].to_i, 1].max # Ensure minimum page 1
    per_page = [[params[:per_page].to_i, 1].max, 100].min # Ensure between 1-100
    @tags = @tags.limit(per_page).offset((page - 1) * per_page)
    
    render json: @tags
  end

  # GET /api/tags/:id
  def show
    # Get playlists with this tag, ensuring non-authenticated users only see public playlists
    playlists = @tag.playlists
    playlists = playlists.public_playlists unless current_user
    
    # Apply pagination to playlists
    page = [params[:page].to_i, 1].max
    per_page = [[params[:per_page].to_i, 1].max, 100].min
    playlists = playlists.limit(per_page).offset((page - 1) * per_page)
    
    render json: @tag.as_json.merge(
      playlists: playlists.as_json(only: [:id, :title, :owner_id])
    )
  end

  # POST /api/tags
  def create
    @tag = Tag.new(tag_params)
    
    if @tag.save
      render json: @tag, status: :created, location: api_tag_url(@tag)
    else
      render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/tags/:id/vote
  def vote
    playlist_id = params[:playlist_id]
    vote_type = params[:vote_type]
    
    # Validate parameters
    if playlist_id.blank?
      return render json: { error: "Playlist ID is required" }, status: :bad_request
    end
    
    unless ['up', 'down', 'remove'].include?(vote_type)
      return render json: { error: "Vote type must be 'up', 'down', or 'remove'" }, status: :bad_request
    end
    
    # Validate playlist exists
    playlist = Playlist.find_by(id: playlist_id)
    unless playlist
      return not_found
    end
    
    # Validate playlist is public or user is owner
    unless playlist.is_public || (current_user && current_user.owns?(playlist))
      return forbidden
    end
    
    # Process the vote
    if @tag.vote(playlist_id, current_user.id, vote_type)
      render json: { 
        votes: @tag.vote_counts(playlist_id),
        user_vote: @tag.user_vote(playlist_id, current_user.id)
      }
    else
      render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
  
  def set_tag
    @tag = Tag.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end
  
  def tag_params
    params.require(:tag).permit(:name)
  end
end