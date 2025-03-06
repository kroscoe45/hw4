class ApplicationController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods
    
    # Handle common errors with standardized responses
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :bad_request
    
    # Standard response for 404 errors
    def not_found
      render json: { error: 'Resource not found' }, status: :not_found
    end
    
    # Standard response for 422 errors
    def unprocessable_entity(exception)
      render json: { error: exception.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
    
    # Standard response for 400 errors
    def bad_request(exception)
      render json: { error: exception.message }, status: :bad_request
    end
    
    # Standard response for 401 errors
    def unauthorized
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
    
    # Standard response for 403 errors
    def forbidden
      render json: { error: 'Forbidden' }, status: :forbidden
    end
    
    private
    
    # Get the current authenticated user
    def current_user
      @current_user ||= authenticate_user
    end
    
    # Check if a user is authenticated
    def authenticate_user
      # This will be implemented with Auth0 JWT verification
      # For now, let's implement a placeholder
      auth_header = request.headers['Authorization']
      token = auth_header&.split(' ')&.last
      
      return nil unless token
      
      # In a real implementation, this would verify the JWT token
      # and extract the auth0_id from it
      auth0_id = extract_auth0_id_from_token(token)
      User.find_by(auth0_id: auth0_id)
    end
    
    # Placeholder method for extracting auth0_id from token
    # This will be replaced with actual JWT verification in production
    def extract_auth0_id_from_token(token)
      # In a real implementation, this would decode and verify the JWT
      # For development purposes, you can return a test user's auth0_id
      'auth0|test_user_id'
    end
    
    # Ensure the user is authenticated before proceeding
    def authenticate_request!
      unless current_user
        return unauthorized
      end
    end
    
    # Ensure the user is an admin before proceeding
    def require_admin!
      authenticate_request!
      return if performed?
      
      unless current_user.admin?
        return forbidden
      end
    end
    
    # Ensure the user is the owner of the resource or an admin
    def require_ownership!(resource)
      authenticate_request!
      return if performed?
      
      unless current_user.admin? || current_user.owns?(resource)
        return forbidden
      end
    end
  end