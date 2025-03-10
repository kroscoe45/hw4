class Api::PlaylistsController < ApplicationController
  include ParameterValidation
  before_action :authenticate_request!, except: [:index, :show, :tracks]
  before_action :set_playlist, except: [:index, :create]
  before_action -> { require_ownership!(@playlist) }, only: [:update, :destroy, :add_track, :remove_track, :update_tracks, :remove_tag]

  # GET /api/playlists
  def index
    @playlists = Playlist.filter_by_params(params, current_user)
    paginated = @playlists.paginate(params)
    
    render json: {
      playlists: paginated[:records],
      meta: paginated[:meta]
    }
  end

  # GET /api/playlists/:id
  def show
    unless @playlist.is_public || (current_user && current_user.owns?(@playlist))
      return forbidden
    end

    render json: @playlist, scope: current_user
  end

  # GET /api/playlists/:id/tracks
  def tracks
    unless @playlist.is_public || (current_user && current_user.owns?(@playlist))
      return forbidden
    end

    if params[:page].present?
      paginated = @playlist.paginated_tracks(params)
      
      render json: {
        tracks: paginated[:records].map { |t| t.as_json(only: [:id, :title, :artist, :added_at]) },
        meta: paginated[:meta]
      }
    else
      render json: @playlist.full_tracks.map { |t| t.as_json(only: [:id, :title, :artist, :added_at]) }
    end
  end

  # POST /api/playlists
  def create
    @playlist = current_user.playlists.new(playlist_params)
    if @playlist.save
      render json: @playlist, status: :created, location: api_playlist_url(@playlist)
    else
      unprocessable_entity(@playlist.errors)
    end
  end

  # PUT /api/playlists/:id
  def update
    if @playlist.update(playlist_params)
      render json: @playlist
    else
      unprocessable_entity(@playlist.errors)
    end
  end

  # DELETE /api/playlists/:id
  def destroy
    @playlist.destroy
    head :no_content
  end

  # POST /api/playlists/:id/tracks
  def add_track
    track_id, error = parse_id(:track_id)
    return render error if error
    
    if @playlist.add_track(track_id)
      render json: @playlist.full_tracks
    else
      unprocessable_entity(@playlist.errors)
    end
  end

  # DELETE /api/playlists/:id/tracks/:track_id
  def remove_track
    if @playlist.remove_track(params[:track_id])
      render json: @playlist.full_tracks
    else
      unprocessable_entity(@playlist.errors)
    end
  end

  # PUT /api/playlists/:id/tracks
  def update_tracks
    track_ids, error = parse_ids(:track_ids)
    return render error if error

    if @playlist.update_track_list(track_ids)
      render json: @playlist.full_tracks
    else
      unprocessable_entity(@playlist.errors)
    end
  end

  # POST /api/playlists/:id/tags
  def add_tag
    tag_name = params[:tag_name]
    
    unless tag_name.present?
      return render json: { error: "Tag name is required" }, status: :bad_request
    end
    
    tag_name, error = validate_tag_name(tag_name)
    return render error if error
    
    tag = @playlist.add_tag(tag_name, current_user.id)
    
    if tag&.persisted?
      render json: @playlist.full_tags
    else
      render json: { errors: tag&.errors&.full_messages || ["Failed to add tag"] }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/playlists/:id/tags/:tag_id
  def remove_tag
    tag = @playlist.tags.find_by(id: params[:tag_id])
    
    # Only allow removal if user is playlist owner or tag creator
    unless current_user.owns?(@playlist) || (tag && tag.user_id == current_user.id)
      return forbidden
    end
    
    if @playlist.remove_tag(params[:tag_id])
      render json: @playlist.full_tags
    else
      render json: { errors: ["Failed to remove tag"] }, status: :unprocessable_entity
    end
  end

  # POST /api/playlists/:id/tags/:tag_id/vote
  def vote_tag
    vote_type = params[:vote_type]
    
    unless ['up', 'down', 'none'].include?(vote_type)
      return render json: { error: "Vote type must be 'up', 'down', or 'none'" }, status: :bad_request
    end
    
    tag = Tag.find(params[:tag_id])
    result = tag.add_vote(current_user.id, @playlist.id, vote_type)
    
    if result
      render json: { 
        id: tag.id,
        name: tag.name,
        votes_up: tag.vote_counts[:up],
        votes_down: tag.vote_counts[:down],
        user_vote: tag.user_vote(current_user.id)
      }
    else
      unprocessable_entity(tag.errors)
    end
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  private

  def set_playlist
    @playlist = Playlist.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  def playlist_params
    params.require(:playlist).permit(:title, :is_public)
  end
  
  # Consistent error handling
  def unprocessable_entity(errors)
    render json: { errors: errors.full_messages || errors }, status: :unprocessable_entity
  end
end