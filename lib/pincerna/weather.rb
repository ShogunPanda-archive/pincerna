# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "oj"
require "restclient"
require "yahoo_weatherman"
require "fileutils"
require "open-uri"

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

    # Get forecast for a place.
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
        caching_http_requests("woeids") do
          request = RestClient::Resource.new("http://where.yahooapis.com/v1/places.q(#{CGI.escape(query)});count=5", timeout: 5, open_timeout: 5)

          Oj.load(request.get({params: {appid: self.class::API_KEY, format: :json}}))["places"]["place"].collect do |place|
            {woeid: place["woeid"], name: ["locality1", "admin3", "admin2", "admin1", "country"].collect { |field| place[field] }.reject(&:empty?).uniq.join(", ")}
          end
        end
      else
        # We already have the woeid. The name will be given by Yahoo!
        [{woeid: query}]
      end
    end

    # Get weather forecast for one or more places.
    #
    # @param places [Array] The places to query.
    # @param scale [String] The unit system to use: `f` for the US system and `c` for the SI one.
    # @return [Array|NilClass] An array with forecasts data or `nil` if the query failed.
    def get_forecast(places, scale = "c")
      client = Weatherman::Client.new(unit: scale)
      temperature_unit = "°#{scale.upcase}"

      places.collect do |place|
        response = client.lookup_by_woeid(place[:woeid])
        current = response.condition
        forecast = response.forecasts.first
        wind = response.wind

        place[:name] ||= get_name(response.location)

        place.merge({
          image: download_image(response.description_image.attr("src")),
          link: response.document_root.at_xpath("link").content,
          current: {
            description: current["text"],
            temperature: "#{current["temp"]} #{temperature_unit}",
            wind: {speed: "#{wind["speed"]} #{response.units["speed"]}", direction: get_wind_direction(wind["direction"])}
          },
          forecast: {
            description: forecast["text"],
            high: "#{forecast["high"]} #{temperature_unit}",
            low: "#{forecast["low"]} #{temperature_unit}"
          },
        })
      end
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
    # @param description [String] The image URL.
    # @return [String] The path of the downloaded image.
    def download_image(url)
      # Extract the URL and use it to build the path
      rv = @cache_dir + "/weather/#{File.basename(URI.parse(url).path)}"

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

    private
  end
end
