module Pincerna
  # Gets weather forecast from Yahoo! Weather.
  class Weather < Base
    # Yahoo! API key.
    API_KEY = "dj0yJmk9ZUpBZk1hQTJGRHM5JmQ9WVdrOVlUSnBjMGhUTjJVbWNHbzlOemsyTURNeU5EWXkmcz1jb25zdW1lcnNlY3JldCZ4PWRi"

    # The expression to match.
    MATCHER = /^
      (.+?) # Place or WOEID
      (\s+in\s+([cf]))? # Temperature unit
    $/mix

    # Relevant groups in the match.
    RELEVANT_MATCHES = {
      1 => Proc.new {|_, value| value }, # Place or WOEID
      3 => Proc.new {|_, value| value.nil? ? nil : value.downcase } # Temperature scale
    }

    # The icon to show for each feedback item.
    ICON = Pincerna::Base::ROOT + "/images/weather.png"

    # Get forecast for a place.
    #
    # @param query [String] A place to search.
    # @return [Array] A list of items to process.
    def perform_filtering(query, scale)
      places = query =~ /^\d+$/ ? query : lookup_places(query)
      places.empty? ? nil : get_forecast(places, scale) if !places.empty?
    end

    # Processes items to obtain feedback items.
    #
    # @param results [Array] The items to process.
    # @return [Array] The feedback items.
    def process_results(results)
      results.collect do |result|
        # Format results
        current = result[:current]
        forecast = result[:forecast]
        combined = "#{current[:temperature]}, #{current[:description].downcase.capitalize}, wind #{current[:wind][:speed]} #{current[:wind][:direction]} - Next: #{forecast[:high]} / #{forecast[:low]}, #{forecast[:description]}"

        {:title => result[:name], :arg => result[:link], :subtitle => combined, :icon => result[:image]}
      end
    end

    # Lookups a place on Yahoo! to obtain WOEID(s).
    #
    # @param query [String] The place to search.
    # @return [Array] A list of matching places data.
    def lookup_places(query)
      rv = []

      begin
        VCR.use_cassette('woeids') do
          if query !~ /^(\d+)$/ then
            request = RestClient::Resource.new("http://where.yahooapis.com/v1/places.q(#{CGI.escape(query)});count=5?appid=#{self.class::API_KEY}", :timeout => 5, :open_timeout => 5)
            
            REXML::Document.new(request.get).elements.each("places/place") do |place|
              # Get woeid and name
              woeid = place.elements["woeid"][0].to_s.strip
              name = ["locality1", "admin3", "admin2", "admin1", "country"].collect {|field| place.elements[field][0].to_s.strip }.reject(&:empty?).uniq          

              rv << {:woeid => woeid, :name => name.join(", ")}
            end
          else
            # We already have the woeid. The name will be given by Yahoo!
            {:woeid => query}
          end
        end
      rescue
        rv = []
      end

      rv
    end

    # Get weather forecast for one or more places.
    #
    # @param places [Array] The places to query.
    # @param scale [String] The unit system to use: `f` for the US system and `c` for the SI one.
    # @return [Array|NilClass] An array with forecasts data or `nil` if the query failed.
    def get_forecast(places, scale = "c")
      rv = nil

      begin
        rv = places.collect do |place|
          request = RestClient::Resource.new("http://weather.yahooapis.com/forecastrss", :timeout => 5, :open_timeout => 5)
          response = REXML::Document.new(request.get({:params => {"w" => place[:woeid], "u" => scale}}))         

          # Get utils elements
          root = response.root.elements["channel"]
          item = root.elements["item"]
          units = root.elements["yweather:units"]
          temperature_unit = units.attributes["temperature"]

          # Get attributes
          name = root.elements["yweather:location"]
          wind = root.elements["yweather:wind"]
          current = item.elements["yweather:condition"]
          forecast = item.elements["yweather:forecast"]
          description = item.elements["description"][0].to_s.strip

          # Override the name if missing
          place[:name] ||= ["city", "region", "country"].collect { |n| name.attributes[n] }.reject(&:empty?).join(", ")

          # Format results
          place.merge({
            :image => get_image(description),
            :link => root.elements["link"][0].to_s,
            :current => {
              :description => current.attributes["text"],
              :temperature => "#{current.attributes["temp"]} #{temperature_unit}",
              :wind => {
                :speed => "#{wind.attributes["speed"]} #{units.attributes["speed"]}",
                :direction => get_wind_direction(wind.attributes["direction"].to_i)
              }
            },
            :forecast => {
              :description => forecast.attributes["text"],
              :high => "#{forecast.attributes["high"]} #{temperature_unit}",
              :low => "#{forecast.attributes["low"]} #{temperature_unit}"
            },
          })
        end
      rescue
      end

      rv
    end

    # Converts the degrees direction of the wind to the N-S, E-W notation.
    #
    # @param degrees [Fixnum] The direction in degrees.
    # @return [String] The direction in N-S, E-W notation.
    def get_wind_direction(degrees) 
      # Get sin and cos for locating.
      radians = degrees * Math::PI / 180 
      sin = round_float(Math.sin(radians), 2)
      cos = round_float(Math.cos(radians), 2)

      # Format result
      rv = ""
      rv << (sin > 0 ? "N" : "S") if sin != 0
      rv << (cos > 0 ? "E" : "W") if cos != 0
      rv
    end

    # Gets and downloads an image for a forecast.
    #
    # @param description [String] The description containing the image URL.
    # @return [String] The path of the downloaded image.
    def get_image(description)
      # Extract the URL and use it to build the path
      url = description.gsub(/^<img src="(.+?)"\/>.+/m, "\\1")
      # TODO@SP: Change this to be in the correct cache dir: http://www.alfredforum.com/topic/307-workflows-best-practices/
      rv = Pincerna::Base::ROOT + "/cache/weather/" + File.basename(URI.parse(url).path)

      # The file is stil missing
      if !File.exists?(rv) then
        begin
          # Create the directory
          FileUtils.mkdir_p(Pincerna::Base::ROOT + "/cache/weather/")
          
          # Download the file
          open(rv, 'wb') {|f| f.write(open(url).read) }
        rescue
        end
      end

      rv
    end
  end
end
