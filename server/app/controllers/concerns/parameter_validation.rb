module ParameterValidation
  extend ActiveSupport::Concern
  # convert string ids to array of integers with error handling
  # [converted_array, nil] on success
  # [nil, error_response] on failure
  # does not validate existence
  def parse_ids(pkey, required: true)
    pval = params[pkey]
    # missing parameter
    if pval.nil?
      return [[], nil] unless required
      return [nil, {
        json: { error: "#{pkey} parameter is required" }, 
        status: :bad_request
      }]
    end
    # non-array parameter
    unless pval.is_a?(Array)
      return [nil, {
        json: { error: "#{pkey} must be an array" },
        status: :bad_request
      }]
    end
    # convert to integers, filtering out invalid values
    result = pval.map { |id| Integer(id.to_s) rescue nil }.compact
    # none of the values were valid integers
    if result.empty? && !pval.empty? && required
      return [nil, {
        json: { error: "#{pkey} contains no valid IDs" },
        status: :bad_request
      }]
    end
    
    [result, nil]
  end
  # validate tag name
  # [name, nil] on success
  # [nil, error_response] on failure
  def validate_tag_name(name)
    if name.nil? || name.empty?
      return [nil, { json: { error: "Tag name is required" }, status: :bad_request }]
    end
    if name.length < 2 || name.length > 20
      return [nil, { json: { error: "Tag name must be between 2 and 20 characters" }, status: :bad_request }]
    end
    [name, nil]
  end
end