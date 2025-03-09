module Paginatable
    extend ActiveSupport::Concern
    
    module ClassMethods
      def paginate(params)
        page = [params[:page].to_i, 1].max
        per_page = [[params[:per_page].to_i, 20].max, 100].min
        
        result = limit(per_page).offset((page - 1) * per_page)
        
        {
          records: result,
          meta: {
            total_count: count,
            current_page: page,
            per_page: per_page,
            total_pages: (count.to_f / per_page).ceil
          }
        }
      end
    end
  end
  
  # Include in Playlist model
  class Playlist < ApplicationRecord
    
    # ...
  end