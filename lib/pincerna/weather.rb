# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Pincerna
  # Gets weather forecast from Yahoo! Weather.
  class Weather < Base
    # Yahoo! API key.
    API_KEY = "dj0yJmk9ZUpBZk1hQTJGRHM5JmQ9WVdrOVlUSnBjMGhUTjJVbWNHbzlOemsyTURNeU5EWXkmcz1jb25zdW1lcnNlY3JldCZ4PWRi"

    # The expression to match.
    MATCHER = /^
      (?<place>.+?)
      (\s+in\s+(?<scale>[cf]))?
    $/mix

    # Relevant groups in the match.
    RELEVANT_MATCHES = {
      "place" => ->(_, value) { value }, # Place or WOEID
      "scale" => ->(_, value) { value.nil? ? "c" : value.downcase } # Temperature scale
    }

    # The icon to show for each feedback item.
    ICON = Pincerna::Base::ROOT + "/images/weather.png"

    # Gets forecast for a place.
    #
    # @param query [String] A place to search.
    # @return [Array] A list of items to process.
    def perform_filtering(query, scale)
      places = lookup_places(query)
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

        {title: result[:name], arg: result[:link], subtitle: combined, icon: result[:image]}
      end
    end

    # Lookups a place on Yahoo! to obtain WOEID(s).
    #
    # @param query [String] The place to search.
    # @return [Array] A list of matching places data.
    def lookup_places(query)
      if query !~ /^(\d+)$/ then
        Pincerna::Cache.instance.use("woeid:#{query}", Pincerna::Cache::EXPIRATIONS[:long]) do
          response = fetch_remote_resource("http://where.yahooapis.com/v1/places.q(#{CGI.escape(query)});count=5", {appid: self.class::API_KEY, format: :json})
          response["places"].fetch("place", []).collect { |place| parse_place(place) }
        end
      else
        # We already have the woeid. The name will be given by Yahoo!
        [{woeid: query}]
      end
    end

    # Gets weather forecast for one or more places.
    #
    # @param places [Array] The places to query.
    # @param scale [String] The unit system to use: `f` for the US system (Farenheit) and `c` for the SI one (Celsius).
    # @return [Array|NilClass] An array with forecasts data or `nil` if the query failed.
    def get_forecast(places, scale = "c")
      client = Weatherman::Client.new(unit: scale)
      temperature_unit = "°#{scale.upcase}"

      places.collect do |place|
        Pincerna::Cache.instance.use("forecast:#{place[:woeid]}", Pincerna::Cache::EXPIRATIONS[:short]) {
          parse_forecast_response(place, client.lookup_by_woeid(place[:woeid]), temperature_unit)
        }
      end
    end

    # Converts the degrees direction of the wind to the cardinal points notation (like NE or SW).
    #
    # @param degrees [Fixnum] The direction in degrees.
    # @return [String] The direction in cardinal points notation.
    def get_wind_direction(degrees)
      # Normalize value
      degrees += 360 if degrees < 0
      degrees = degrees % 360

      # Get the position
      directions = ["N", "NE", "NE", "E", "E", "SE", "SE", "S", "S", "SW", "SW", "W", "W", "NW", "NW", "N"]
      position = ((degrees.to_f / 22.5) - 0.5).ceil.to_i % directions.count # The mod operation is needed for values close to 360 who, after ceiling, would otherwise overflow.
      directions[position]
    end

    private
      # Gets and downloads an image for a forecast.
      #
      # @param url [String] The image URL.
      # @return [String] The path of the downloaded image.
      def download_image(url)
        # Extract the URL and use it to build the path
        rv = (@cache_dir + "/weather/#{File.basename(URI.parse(url).path)}")

        if !File.exists?(rv) then
          # Create the directory and download the file
          FileUtils.mkdir_p(@cache_dir + "/weather/")
          open(rv, 'wb') {|f| f.write(open(url).read) }
        end

        rv
      end

      # Gets a location name.
      #
      # @param location [Hash] The location data.
      # @return [String] The location name.
      def get_name(location)
        ["city", "region", "country"].collect { |field| location[field].strip }.reject(&:empty?).join(", ")
      end

      # Parses a WOEID lookup.
      #
      # @param place [Hash] The place to parse.
      # @return [Hash] The parsed place.
      def parse_place(place)
        {
          woeid: place["woeid"],
          name: ["locality1", "admin3", "admin2", "admin1", "country"].collect { |field| place[field] }.reject(&:empty?).uniq.join(", ")
        }
      end

      # Formats a weather forecast.
      #
      # @param place [Hash] The basic place information.
      # @param response [Weatherman::Response] The forecast response.
      # @param temperature_unit [String] The temperature unit.
      # @return [Hash] A formatted forecast.
      def parse_forecast_response(place, response, temperature_unit)
        image, link = extract_forecast_media(response)
        place[:name] ||= get_name(response.location)

        format_forecast(place, download_image(image), link, response.condition, response.forecasts.first, response.wind, temperature_unit, response.units["speed"])
      end

      # Formats a weather forecast.
      #
      # @param place [Hash] The basic place information.
      # @param image [String] The icon for the current weather conditions.
      # @param link [String] The link to view weather conditions on Yahoo!.
      # @param current [Hash] The current weather conditions.
      # @param forecast [Hash] The weather forecast for tomorrow.
      # @param wind [Hash] The current wind conditions.
      # @param temperature_unit [String] The temperature unit.
      # @param speed_unit [String] The speed unit.
      # @return [Hash] The parsed forecast.
      def format_forecast(place, image, link, current, forecast, wind, temperature_unit, speed_unit)
        place.merge({
          image: image,
          link: link,
          current: {
            description: current["text"],
            temperature: "#{current["temp"]} #{temperature_unit}",
            wind: {speed: "#{wind["speed"]} #{speed_unit}", direction: get_wind_direction(wind["direction"])}
          },
          forecast: {
            description: forecast["text"],
            high: "#{forecast["high"]} #{temperature_unit}",
            low: "#{forecast["low"]} #{temperature_unit}"
          },
        })
      end

      # Extracts forecast media from a response.
      #
      # @param response The response to analyze.
      # @return [Array] An array of media.
      def extract_forecast_media(response)
        [response.description_image.attr("src"), response.document_root.at_xpath("link").content.to_s]
      end
  end
end
