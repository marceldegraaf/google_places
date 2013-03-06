require 'google_places/review'

module GooglePlaces
  class Spot
    attr_accessor :lat, :lng, :name, :icon, :reference, :vicinity, :types, :id, :formatted_phone_number, :international_phone_number, :formatted_address, :address_components, :street_number, :street, :city, :region, :postal_code, :country, :rating, :url, :cid, :website, :reviews

    # Search for Spots at the provided location
    #
    # @return [Array<Spot>]
    # @param [String,Integer] lat the latitude for the search
    # @param [String,Integer] lng the longitude for the search
    # @param [String] api_key the provided api key
    # @param [Boolean] sensor
    #   Indicates whether or not the Place request came from a device using a location sensor (e.g. a GPS) to determine the location sent in this request.
    #   <b>Note that this is a mandatory parameter</b>
    # @param [Hash] options
    # @option options [Integer] :radius (1000)
    #   Defines the distance (in meters) within which to return Place results.
    #   The maximum allowed radius is 50,000 meters.
    #   Note that radius must not be included if :rankby => 'distance' (described below) is specified.
    #   <b>Note that this is a mandatory parameter</b>
    # @option options [String] :rankby
    #   Specifies the order in which results are listed. Possible values are:
    #   - prominence (default). This option sorts results based on their importance.
    #     Ranking will favor prominent places within the specified area.
    #     Prominence can be affected by a Place's ranking in Google's index,
    #     the number of check-ins from your application, global popularity, and other factors.
    #   - distance. This option sorts results in ascending order by their distance from the specified location.
    #     Ranking results by distance will set a fixed search radius of 50km.
    #     One or more of keyword, name, or types is required.                                                                                                                                                                                                                                                                                       distance. This option sorts results in ascending order by their distance from the specified location. Ranking results by distance will set a fixed search radius of 50km. One or more of keyword, name, or types is required.
    # @option options [String,Array] :types
    #   Restricts the results to Spots matching at least one of the specified types
    # @option options [String] :name
    #   A term to be matched against the names of Places.
    #   Results will be restricted to those containing the passed name value.
    # @option options [String] :keyword
    #   A term to be matched against all content that Google has indexed for this Spot,
    #   including but not limited to name, type, and address,
    #   as well as customer reviews and other third-party content.
    # @option options [String] :language
    #   The language code, indicating in which language the results should be returned, if possible.
    # @option options [String,Array<String>] :exclude ([])
    #   A String or an Array of <b>types</b> to exclude from results
    #
    # @option options [Hash] :retry_options ({})
    #   A Hash containing parameters for search retries
    # @option options [Object] :retry_options[:status] ([])
    # @option options [Integer] :retry_options[:max] (0) the maximum retries
    # @option options [Integer] :retry_options[:delay] (5) the delay between each retry in seconds
    #
    # @see http://spreadsheets.google.com/pub?key=p9pdwsai2hDMsLkXsoM05KQ&gid=1 List of supported languages
    # @see https://developers.google.com/maps/documentation/places/supported_types List of supported types
    def self.list(lat, lng, api_key, sensor, options = {})
      location = Location.new(lat, lng)
      rankby = options.delete(:rankby)
      radius = options.delete(:radius) || 1000 if rankby.nil?
      types  = options.delete(:types)
      name  = options.delete(:name)
      keyword = options.delete(:keyword)
      language  = options.delete(:language)
      exclude = options.delete(:exclude) || []
      retry_options = options.delete(:retry_options) || {}

      exclude = [exclude] unless exclude.is_a?(Array)

      options = {
        :location => location.format,
        :radius => radius,
        :sensor => sensor,
        :rankby => rankby,
        :key => api_key,
        :name => name,
        :language => language,
        :keyword => keyword,
        :retry_options => retry_options
      }

      # Accept Types as a string or array
      if types
        types = (types.is_a?(Array) ? types.join('|') : types)
        options.merge!(:types => types)
      end

      results = []
      self.multi_pages_request(:spots, options) do |result|
        results << self.new(result) if (result['types'] & exclude) == []
      end
      results
    end

    # Search for a Spot with a reference key
    #
    # @return [Spot]
    # @param [String] reference the reference of the spot
    # @param [String] api_key the provided api key
    # @param [Boolean] sensor
    #   Indicates whether or not the Place request came from a device using a location sensor (e.g. a GPS)
    #   to determine the location sent in this request.
    #   <b>Note that this is a mandatory parameter</b>
    # @param [Hash] options
    # @option options [String] :language
    #   The language code, indicating in which language the results should be returned, if possible.
    #
    # @option options [Hash] :retry_options ({})
    #   A Hash containing parameters for search retries
    # @option options [Object] :retry_options[:status] ([])
    # @option options [Integer] :retry_options[:max] (0) the maximum retries
    # @option options [Integer] :retry_options[:delay] (5) the delay between each retry in seconds
    def self.find(reference, api_key, sensor, options = {})
      language  = options.delete(:language)
      retry_options = options.delete(:retry_options) || {}

      response = Request.spot(
        :reference => reference,
        :sensor => sensor,
        :key => api_key,
        :language => language,
        :retry_options => retry_options
      )

      self.new(response['result'])
    end

    # Search for Spots with a query
    #
    # @return [Array<Spot>]
    # @param [String] query the query to search for
    # @param [String] api_key the provided api key
    # @param [Boolean] sensor
    #   Indicates whether or not the Place request came from a device using a location sensor (e.g. a GPS)
    #   to determine the location sent in this request.
    #   <b>Note that this is a mandatory parameter</b>
    # @param [Hash] options
    # @option options [String,Integer] :lat
    #   the latitude for the search
    # @option options [String,Integer] :lng
    #   the longitude for the search
    # @option options [Integer] :radius (1000)
    #   Defines the distance (in meters) within which to return Place results.
    #   The maximum allowed radius is 50,000 meters.
    #   Note that radius must not be included if :rankby => 'distance' (described below) is specified.
    #   <b>Note that this is a mandatory parameter</b>
    # @option options [String] :rankby
    #   Specifies the order in which results are listed. Possible values are:
    #   - prominence (default). This option sorts results based on their importance.
    #     Ranking will favor prominent places within the specified area.
    #     Prominence can be affected by a Place's ranking in Google's index,
    #     the number of check-ins from your application, global popularity, and other factors.
    #   - distance. This option sorts results in ascending order by their distance from the specified location.
    #     Ranking results by distance will set a fixed search radius of 50km.
    #     One or more of keyword, name, or types is required.
    # @option options [String,Array] :types
    #   Restricts the results to Spots matching at least one of the specified types
    # @option options [String] :language
    #   The language code, indicating in which language the results should be returned, if possible.
    # @option options [String,Array<String>] :exclude ([])
    #   A String or an Array of <b>types</b> to exclude from results
    #
    # @option options [Hash] :retry_options ({})
    #   A Hash containing parameters for search retries
    # @option options [Object] :retry_options[:status] ([])
    # @option options [Integer] :retry_options[:max] (0) the maximum retries
    # @option options [Integer] :retry_options[:delay] (5) the delay between each retry in seconds
    #
    # @see http://spreadsheets.google.com/pub?key=p9pdwsai2hDMsLkXsoM05KQ&gid=1 List of supported languages
    # @see https://developers.google.com/maps/documentation/places/supported_types List of supported types
    def self.list_by_query(query, api_key, sensor, options = {})
      if options.has_key?(:lat) && options.has_key?(:lng)
        with_location = true
      else
        with_location = false
      end

      if options.has_key?(:radius)
        with_radius = true
      else
        with_radius = false
      end

      query = query
      sensor = sensor
      location = Location.new(options.delete(:lat), options.delete(:lng)) if with_location
      radius = options.delete(:radius) if with_radius
      rankby = options.delete(:rankby)
      language = options.delete(:language)
      types = options.delete(:types)
      exclude = options.delete(:exclude) || []
      retry_options = options.delete(:retry_options) || {}

      exclude = [exclude] unless exclude.is_a?(Array)

      options = {
        :query => query,
        :sensor => sensor,
        :key => api_key,
        :rankby => rankby,
        :language => language,
        :retry_options => retry_options
      }

      options[:location] = location.format if with_location
      options[:radius] = radius if with_radius

      # Accept Types as a string or array
      if types
        types = (types.is_a?(Array) ? types.join('|') : types)
        options.merge!(:types => types)
      end

      results = []
      self.multi_pages_request(:spots_by_query, options) do |result|
        results << self.new(result) if (result['types'] & exclude) == []
      end
      results
    end

    def self.multi_pages_request(method, options)
      

        response = Request.send(method, options)
        response['results'].each do |result|
          yield(result)
        end

    end

    # @param [JSON] json_result_object a JSON object to create a Spot from
    # @return [Spot] a newly created spot
    def initialize(json_result_object)
      @reference                  = json_result_object['reference']
      @vicinity                   = json_result_object['vicinity']
      @lat                        = json_result_object['geometry']['location']['lat']
      @lng                        = json_result_object['geometry']['location']['lng']
      @name                       = json_result_object['name']
      @icon                       = json_result_object['icon']
      @types                      = json_result_object['types']
      @id                         = json_result_object['id']
      @formatted_phone_number     = json_result_object['formatted_phone_number']
      @international_phone_number = json_result_object['international_phone_number']
      @formatted_address          = json_result_object['formatted_address']
      @address_components         = json_result_object['address_components']
      @street_number              = address_component(:street_number, 'short_name')
      @street                     = address_component(:route, 'long_name')
      @city                       = address_component(:locality, 'long_name')
      @region                     = address_component(:administrative_area_level_1, 'long_name')
      @postal_code                = address_component(:postal_code, 'long_name')
      @country                    = address_component(:country, 'long_name')
      @rating                     = json_result_object['rating']
      @url                        = json_result_object['url']
      @cid                        = json_result_object['url'].to_i
      @website                    = json_result_object['website']
      @reviews                    = reviews_component(json_result_object['reviews'])
    end

    def address_component(address_component_type, address_component_length)
      if component = address_components_of_type(address_component_type)
        component.first[address_component_length] unless component.first.nil?
      end
    end

    def address_components_of_type(type)
      @address_components.select{ |c| c['types'].include?(type.to_s) } unless @address_components.nil?
    end

    def reviews_component(json_reviews)
      if json_reviews
        json_reviews.map { |r|
          Review.new(
              r['aspects'].empty? ? nil : r['aspects'][0]['rating'],
              r['aspects'].empty? ? nil : r['aspects'][0]['type'],
              r['author_name'],
              r['author_url'],
              r['text'],
              r['time'].to_i
          )
        }
      else []
      end
    end

  end
end
