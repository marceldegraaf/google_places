module GooglePlaces
  class Prediction
    DEFAULT_RADIUS = 1000
    DEFAULT_SENSOR = false

    attr_accessor(
      :description,
      :id,
      :reference,
    )

    def initialize(json_result_object)
      @description = json_result_object['description']
      @id = json_result_object['id']
      @reference = json_result_object['reference']
    end

    # Query for Predictions (optionally at the provided location)
    #
    # @option [Boolean] :sensor
    #   Indicates whether or not the Place request came from a device using a location sensor (e.g. a GPS) to determine the location sent in this request.
    #   <b>Note that this is a mandatory parameter</b>
    # @option [String,Integer] :lat the latitude for the search
    # @option [String,Integer] :lng the longitude for the search
    # @option options [Integer] :radius (1000)
    #   Defines the distance (in meters) within which to return Place results.
    #   The maximum allowed radius is 50,000 meters.
    #   Note that radius must not be included if :rankby => 'distance' (described below) is specified.
    #   <b>Note that this is a mandatory parameter</b>
    # @option options [String,Array] :types
    #   Restricts the results to Spots matching at least one of the specified types
    # @option options [String] :language
    #   The language code, indicating in which language the results should be returned, if possible.
    # @option options [Hash] :retry_options ({})
    #   A Hash containing parameters for search retries
    # @option options [Object] :retry_options[:status] ([])
    # @option options [Integer] :retry_options[:max] (0) the maximum retries
    # @option options [Integer] :retry_options[:delay] (5) the delay between each retry in seconds
    def self.list_by_input(input, api_key, options = {})
      lat = options.delete(:lat)
      lng = options.delete(:lng)
      language = options.delete(:language)
      radius = options.delete(:radius) || DEFAULT_RADIUS
      retry_options = options.delete(:retry_options) || {}
      sensor = options.delete(:sensor) || DEFAULT_SENSOR
      types  = options.delete(:types)

      options = {
        :input => input,
        :key => api_key,
        :retry_options => retry_options,
        :sensor => sensor
      }

      if lat && lng
        options[:location] = Location.new(lat, lng).format
        options[:radius] = radius
      end

      # Accept Types as a string or array
      if types
        types = (types.is_a?(Array) ? types.join('|') : types)
        options[:types] = types
      end

      if language
        options[:language] = language
      end

      request(:predictions_by_input, options)
    end

    def self.request(method, options)
      response = Request.send(method, options)

      response['predictions'].map do |result|
        self.new(result)
      end
    end
  end
end
