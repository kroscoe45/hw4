module IdConverter
    extend ActiveSupport::Concern
    
    included do
      before_action :convert_id_params
    end
    
    private
    
    # Convert ID parameters from strings to integers
    def convert_id_params
      # Convert common ID parameters in the URL
      convert_param(:id)
      convert_param(:playlist_id)
      convert_param(:track_id)
      convert_param(:tag_id)
      convert_param(:user_id)
      
      # Handle arrays of IDs
      convert_param_array(:track_ids) if params[:track_ids].present?
      convert_param_array(:tag_ids) if params[:tag_ids].present?
    end
    
    # Convert a single parameter to integer
    def convert_param(key)
      if params[key].present? && params[key].is_a?(String)
        params[key] = params[key].to_i
      end
    end
    
    # Convert an array parameter to array of integers
    def convert_param_array(key)
      if params[key].is_a?(Array)
        params[key] = params[key].map(&:to_i)
      end
    end
  end