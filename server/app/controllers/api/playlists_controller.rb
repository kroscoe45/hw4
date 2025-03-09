class Api::PlaylistsController < ApplicationController
  include ParameterValidation
  before_action :authenticate_request!, except: [:index, :show, :tracks]
  before_action :set_playlist, except: [:index, :create]
  before_action -> { require_ownership!(@playlist) }, only: [:update, :destroy, :add_track, :remove_track, :update_tracks, :remove_tag]

  # GET /api/playlists
  def index
    @playlists = Playlist.filter_by_params(params, current_user)
    @playlists = paginate(@playlists)
    render json: @playlists
  end

  # GET /api/playlists/:id
  def show
    unless @playlist.is_public || (current_user && current_user.owns?(@playlist))
      return forbidden
    end

    tracks = @playlist.full_tracks
    tags = @playlist.full_tags

    user_votes = {}
    if current_user
      tags.each do |tag|
        user_votes[tag.id] = tag.user_vote(current_user.id, @playlist.id)
      end
    end

    response = {
      id: @playlist.id,
      title: @playlist.title,
      is_public: @playlist.is_public,
      owner: {
        id: @playlist.owner.id,
        username: @playlist.owner.username
      },
      tracks: tracks.map { |t| t.as_json(only: [:id, :title, :artist, :added_at]) },
      tags: tags.map { |t|
        tag_json = t.as_json(only: [:id, :name])
        vote_counts = t.vote_counts(@playlist.id)
        tag_json.merge(
          votes_up: vote_counts[:up],
          votes_down: vote_counts[:down],
          user_vote: current_user ? user_votes[t.id] : nil
        )
      },
      created_at: @playlist.created_at,
      updated_at: @playlist.updated_at
    }

    render json: response
  end

  # GET /api/playlists/:id/tracks
  def tracks
    unless @playlist.is_public || (current_user && current_user.owns?(@playlist))
      return forbidden
    end

    tracks = @playlist.full_tracks
    if params[:page].present?
      tracks = paginate(tracks)
      render json: {
        tracks: tracks.map { |t| t.as_json(only: [:id, :title, :artist, :added_at]) },
        meta: pagination_meta(tracks)
      }
    else
      render json: tracks.map { |t| t.as_json(only: [:id, :title, :artist, :added_at]) }
    end
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

    Tag.transaction do
      tag = Tag.find_or_initialize_by(name: tag_name)
      if @playlist.tags.exists?(name: tag_name)
        return render json: { error: "Tag already attached to playlist" }, status: :conflict
      end
      if tag.new_record?
        tag.attached_to = create_attached_to
        unless tag.save
          return render json: { errors: tag.errors.full_messages }, status: :unprocessable_entity
        end
      end
      if @playlist.add_tag(tag.name, current_user.id)
        render json: @playlist.full_tags
      else
        render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  # DELETE /api/playlists/:id/tags/:tag_name
  def remove_tag
    tag_name = params[:tag_name]
    if @playlist.remove_tag(tag_name)
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

  def create_attached_to
    {
      "vote_up" => [],
      "vote_down" => [],
      "suggested_by" => current_user.id.to_s
    }
  end

  def paginate(collection)
    page = [params[:page].to_i, 1].max
    per_page = [[params[:per_page].to_i, 1].max, 100].min
    collection.limit(per_page).offset((page - 1) * per_page)
  end

  def pagination_meta(collection)
    {
      total_count: collection.size,
      current_page: params[:page].to_i,
      per_page: params[:per_page].to_i,
      total_pages: (collection.size.to_f / params[:per_page].to_i).ceil
    }
  end
end