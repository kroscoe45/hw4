class Api::PlaylistsController < ApplicationController
  include ParameterValidation
  before_action :authenticate_request!, except: [:index, :show, :tracks]
  before_action :set_playlist, except: [:index, :create]
  before_action -> { require_ownership!(@playlist) }, only: [:update, :destroy, :add_track, :remove_track, :update_tracks, :remove_tag]
  
  # GET /api/playlists
  def index
    @playlists = if params[:owner_id].present?
      Playlist.by_owner(params[:owner_id])
    elsif params[:tag_id].present?
      Playlist.with_tag(params[:tag_id])
    elsif params[:track_id].present?
      Playlist.with_track(params[:track_id])
    else
      Playlist.all
    end
    
    # Filter for public playlists unless user is authenticated
    @playlists = @playlists.public_playlists unless current_user
    
    # Apply optional sorting
    @playlists = @playlists.recent if params[:sort] == 'recent'
    
    # Apply pagination (default: 20 per page)
    page = [params[:page].to_i, 1].max # Ensure minimum page 1
    per_page = [[params[:per_page].to_i, 1].max, 100].min # Ensure between 1-100
    @playlists = @playlists.limit(per_page).offset((page - 1) * per_page)
    
    render json: @playlists
  end

  # GET /api/playlists/:id
  def show
    # Check if playlist is public or user is owner
    unless @playlist.is_public || (current_user && current_user.owns?(@playlist))
      return forbidden
    end
    
    # Preload associations to avoid N+1 queries
    tracks = @playlist.full_tracks
    tags = @playlist.full_tags
    
    render json: @playlist.as_json(
      include: {
        owner: { only: [:id, :username] }
      }
    ).merge(
      tracks: tracks.as_json(except: [:created_at, :updated_at]),
      tags: tags.as_json(except: [:created_at, :updated_at])
    )
  end

  # GET /api/playlists/:id/tracks
  def tracks
    # Check if playlist is public or user is owner
    unless @playlist.is_public || (current_user && current_user.owns?(@playlist))
      return forbidden
    end
    
    render json: @playlist.full_tracks
  end

  # POST /api/playlists
  def create
    @playlist = current_user.playlists.new(playlist_params)
    
    if @playlist.save
      render json: @playlist, status: :created, location: api_playlist_url(@playlist)
    else
      render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/playlists/:id
  def update
    if @playlist.update(playlist_params)
      render json: @playlist
    else
      render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/playlists/:id
  def destroy
    @playlist.destroy
    head :no_content
  end

  # POST /api/playlists/:id/tracks
  def add_track
    track_id = params[:track_id]
    
    if track_id.blank?
      return render json: { error: "Track ID is required" }, status: :bad_request
    end
    
    if @playlist.add_track(track_id)
      render json: @playlist.full_tracks
    else
      render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/playlists/:id/tracks/:track_id
  def remove_track
    track_id = params[:track_id]
    
    if @playlist.remove_track(track_id)
      render json: @playlist.full_tracks
    else
      render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/playlists/:id/tracks
  def update_tracks
    track_ids, error = parse_ids(:track_ids)
    return render error if error

    if @playlist.update_track_list(track_ids)
      render json: @playlist.full_tracks
    else
      render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/playlists/:id/tags
  def add_tag
    tag_name, error = validate_tag_name(params[:tag_name])
    return render error if error
    tag_id, error = parse_ids(:tag_id)

    Tag.transaction do
      tag_name = tag_name.strip
      # If the tag is already in the database and attached to the playlist, return an error
      if @playlist.tags.include?(tag_id)
        return render json: { error: "Tag already attached to playlist" }, status: :unprocessable_entity
      end
      # If the tag is not in the database, create it
      if tag.attached_to.nil?
        tag.attached_to = {}
      end
      tag.attached_to[@playlist.id.to_s] = { 
        "voteUp" => [],
        "voteDown" => [],
        "suggestedBy" => current_user.id.to_s 
      }
      if @playlist.add_tag(tag_id, current_user.id)
        render json: @playlist.full_tags
      else
        render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  # DELETE /api/playlists/:id/tags/:tag_id
  def remove_tag
    tag_id = params[:tag_id]
    
    if @playlist.remove_tag(tag_id)
      render json: @playlist.full_tags
    else
      render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_entity
    end
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

  def create_new_tag(tag_name)
    tag = Tag.new(name: tag_name)
    tag.attached_to = { @playlist.id.to_s => { 
      "vote_up" => [], 
      "vote_down" => [], 
      "suggested_by" => current_user.id.to_s 
    }}
    
    tag.save
    tag
  end

  def add_existing_tag(tag)
    if tag.attached_to[@playlist.id.to_s].nil?
      tag.attached_to[@playlist.id.to_s] = {
        "vote_up" => [],
        "vote_down" => [],
        "suggested_by" => current_user.id.to_s
      }
      
      unless tag.save
        return { json: { errors: tag.errors.full_messages }, status: :unprocessable_entity }
      end
    else
      # Tag already attached to this playlist
      return { json: { message: "Tag already added to this playlist" }, status: :ok }
    end
    nil
  end
end