class Api::TracksController < ApplicationController
  include ParameterValidation
  before_action :authenticate_request!, except: [:index, :show]
  before_action :set_track, only: [:show, :update, :destroy]
  before_action :require_admin!, only: [:create, :update, :destroy]

  # GET /api/tracks
  def index
    @tracks = if params[:artist].present?
      Track.by_artist(params[:artist])
    elsif params[:title].present?
      Track.search_title(params[:title])
    else
      Track.all
    end
    
    # Apply sorting
    @tracks = @tracks.order(created_at: :desc) if params[:sort] == 'recent'
    
    # Apply pagination
    page = [params[:page].to_i, 1].max
    per_page = [[params[:per_page].to_i, 20].max, 100].min
    
    paginated = @tracks.paginate(page: page, per_page: per_page)
    
    render json: {
      tracks: paginated,
      meta: {
        total_count: @tracks.count,
        current_page: page,
        per_page: per_page,
        total_pages: (@tracks.count.to_f / per_page).ceil
      }
    }
  end

  # GET /api/tracks/:id
  def show
    render json: @track
  end

  # POST /api/tracks
  def create
    @track = Track.new(track_params)
    
    if @track.save
      render json: @track, status: :created, location: api_track_url(@track)
    else
      render json: { errors: @track.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PUT /api/tracks/:id
  def update
    if @track.update(track_params)
      render json: @track
    else
      render json: { errors: @track.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/tracks/:id
  def destroy
    @track.destroy
    head :no_content
  end

  private
  
  def set_track
    @track = Track.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end
  
  def track_params
    params.require(:track).permit(:title, :artist)
  end
end