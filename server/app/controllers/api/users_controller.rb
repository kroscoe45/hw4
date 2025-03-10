class Api::UsersController < ApplicationController
  include ParameterValidation
  before_action :authenticate_request!, except: [:create]
  before_action :set_user, only: [:show, :update]
  before_action -> { require_ownership!(@user) }, only: [:update]
  
  # GET /api/users/:id
  def show
    render json: @user
  end

  # POST /api/users
  def create
    # This would typically be handled by Auth0 registration
    # and only profile completion would be managed here
    @user = User.new(user_params)
    
    if @user.save
      render json: @user, status: :created, location: api_user_url(@user)
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/users/:id
  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    not_found
  end
  
  def user_params
    # Only allow updating username, not auth0_id or roles
    params.require(:user).permit(:username)
  end
end