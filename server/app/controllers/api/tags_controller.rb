class Api::TagsController < ApplicationController
  include ParameterValidation
  before_action :authenticate_request!, except: [:index, :show]
  before_action :set_tag, only: [:show, :vote, :destroy]
  before_action -> { require_ownership!(@tag) }, only: [:destroy]
  
  # GET /api/tags
  def index
    @tags = if params[:playlist_id].present?
      Tag.by_playlist(params[:playlist_id])
    elsif params[:name].present?
      Tag.by_name(params[:name])
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
    
    # Apply pagination
    paginated = @tags.paginate(params)
    
    render json: {
      tags: paginated[:records],
      meta: paginated[:meta]
    }
  end

  # GET /api/tags/:id
  def show
    # Get playlists with this tag name, ensuring non-authenticated users only see public playlists
    playlists = Tag.find_playlists_with_tag_name(@tag.name)
    playlists = playlists.public_playlists unless current_user
    
    # Apply pagination to playlists
    page = [params[:page].to_i, 1].max
    per_page = [[params[:per_page].to_i, 1].max, 100].min
    paginated_playlists = playlists.limit(per_page).offset((page - 1) * per_page)
    
    render json: @tag.as_json.merge(
      playlists: paginated_playlists.as_json(only: [:id, :title, :owner_id]),
      meta: {
        total_playlists: playlists.count,
        current_page: page,
        per_page: per_page,
        total_pages: (playlists.count.to_f / per_page).ceil
      }
    )
  end

  # POST /api/tags
  def create
    playlist_id, error = parse_id(:playlist_id)
    return render error if error

    playlist = Playlist.find(playlist_id)
    
    # Check if user can add tag to this playlist
    unless playlist.is_public || current_user.owns?(playlist)
      return forbidden
    end
    
    @tag = Tag.new(tag_params)
    @tag.playlist = playlist
    @tag.user = current_user
    
    if @tag.save
      render json: @tag, status: :created, location: api_tag_url(@tag)
    else
      render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end
  
  # DELETE /api/tags/:id
  def destroy
    @tag.destroy
    head :no_content
  end

  # POST /api/tags/:id/vote
  def vote
    vote_type = params[:vote_type]
    
    unless ['up', 'down', 'remove'].include?(vote_type)
      return render json: { error: "Vote type must be 'up', 'down', or 'remove'" }, status: :bad_request
    end
    
    # Map 'remove' to nil for the UserVote.vote method
    vote_value = vote_type == 'remove' ? nil : vote_type
    
    if UserVote.vote(current_user.id, @tag.id, vote_value)
      render json: { 
        votes: @tag.vote_counts,
        user_vote: @tag.user_vote(current_user.id)
      }
    else
      render json: { errors: ["Failed to register vote"] }, status: :unprocessable_entity
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