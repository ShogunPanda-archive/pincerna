# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

# A bunch of useful Alfred 2 workflows.
module Pincerna
  # Base class for all filter.
  #
  # @attribute [r] output
  #   @return [String] The output of filtering.
  # @attribute [r] format
  #   @return [Symbol] The format of output. Can be `:xml` (default) or `:yml`.
  # @attribute [r] format_content_type
  #   @return [Symbol] The content type of the format. Can be `:xml` (default) or `:yml`.
  class Base
    # Recognized types of filtering
    TYPES = {
      "unit_conversion" => /^(convert|unit|c)$/,
      "currency_conversion" => /^(currency|cc)$/,
      "translation" => /^(translate|t)$/,
      "map" => /^(map|m)$/,
      "weather" => /^(forecast|weather)$/,
      "ip" => /^ip$/,
      "vpn" => /^vpn$/,
      "chrome_bookmark" => /^(chrome-bookmark|bc)$/,
      "safari_bookmark" => /^(safari-bookmark|bs)$/,
      "firefox_bookmark" => /^(firefox-bookmark|bf)$/
    }

    ROOT = File.expand_path(File.dirname(__FILE__) + "/../../")

    # The expression to match.
    MATCHER = /^(?<all>.*)$/i

    # Relevant groups in the match.
    RELEVANT_MATCHES = {
      "all" => ->(_, value) { value }
    }

    attr_reader :output, :format, :format_content_type

    # Executes a filtering query.
    #
    # @param type [Symbol] The type of the query.
    # @param query [String] The argument of the query.
    # @param format [String] The format to use. Valid values are `:xml` (default) and `:yml`.
    # @param debug [String] The debug mode.
    # @return [String] The result of the query.
    def self.execute!(type, query, format = :xml, debug = nil)
      instance = nil

      type = catch(:type) do
        TYPES.each do |file, matcher|
          throw(:type, file) if type =~ matcher
        end

        nil
      end

      if type
        instance = find_class(type).new(query, format, debug)
        instance.filter
      end

      instance
    end

    # Creates a new query.
    #
    # @param query [String] The argument of the query.
    # @param requested_format [String] The format to use. Valid values are `:xml` (default) and `:yml`.
    # @param debug [String] The debug mode.
    def initialize(query, requested_format = :xml, debug = nil)
      @query = query.strip.gsub("\\ ", " ")
      @cache_dir = File.expand_path("~/Library/Caches/com.runningwithcrayons.Alfred-2/Workflow Data/pincerna")

      if requested_format =~ /^y(a?)ml$/ then
        @format = :yml
        @format_content_type = "text/x-yaml"
      else
        @format = :xml
        @format_content_type = "text/xml"
      end

      @debug = debug
      @feedback_items = []
    end

    # Filters a query.
    #
    # @return [String] The feedback items of the query, formatted as XML.
    def filter
      # Match the query
      matches = self.class::MATCHER.match(@query)

      if matches then
        # Execute the filtering
        results = execute_filtering(matches)

        # Show results if appropriate
        process_results(results).each {|r| add_feedback_item(r) } if !results.empty?
      end

      output_feedback
    end

    # Filters a query.
    #
    # @param args [Array] The arguments of the query.
    # @return [Array] A list of items to process.
    def perform_filtering(*args)
      raise ArgumentError.new("Must be overriden by subclasses.")
    end

    # Processes items to obtain feedback items.
    #
    # @param results [Array] The items to process.
    # @return [Array] The feedback items.
    def process_results(results)
      raise ArgumentError.new("Must be overriden by subclasses.")
    end

    # Adds a feedback items.
    #
    # @param item [Array] The items to add.
    def add_feedback_item(item)
      @feedback_items << item
    end

    # Outputs the feedback.
    #
    # @return [String] A XML document.
    def output_feedback
      if format == :xml then
        @output = Nokogiri::XML::Builder.new { |xml|
          xml.items do
            @feedback_items.each do |item|
              childs, attributes = split_output_item(item)

              xml.item(attributes) do
                childs.each { |name, value| xml.send(name, value) }
              end
            end
          end
        }.to_xml
      else
        @output = @feedback_items.to_yaml
      end
    end

    # Rounds a float to a certain precision.
    #
    # @param value [Float] The value to convert.
    # @param precision [Fixnum] The precision to use.
    # @return [Float] The rounded value.
    def round_float(value, precision = 3)
      factor = 10**precision
      (value * factor).round.to_f / factor
    end

    # Rounds a float to a certain precision and prints it as a string. Unneeded leading zero are remove.
    #
    # @param value [Float] The value to print.
    # @param precision [Fixnum] The precision to use.
    # @return [String] The formatted value.
    def format_float(value, precision = 3)
      value = round_float(value, precision)
      value = "%0.#{precision}f" % value
      value.gsub(/\.?0+$/, "")
    end

    protected
      # Instantiates the new class.
      #
      # @param file [String] The file name.
      def self.find_class(file)
        Pincerna.const_get(file.capitalize.gsub(/_(.)/) { $1.upcase})
      end

      # Executes filtering on matched data.
      #
      # @param matches [MatchData] The matched data.
      # @return [Array] The results of filtering.
      def execute_filtering(matches)
        # Get relevant matches and arguments.
        relevant = self.class::RELEVANT_MATCHES
        args = relevant.collect {|key, value| value.call(self, matches[key]) }

        # Now perform the operation
        begin
          perform_filtering(*args)
        rescue => e
          raise e if debug_mode == :error
          []
        end
      end

      # Converts an array of key-value pairs to an hash.
      #
      # @param array [Array] The array to convert.
      # @return [Hash] The converted hash.
      def array_to_hash(array)
        array.inject({}){ |rv, entry|
          rv[entry[0]] = entry[1]
          rv
        }
      end

      # Gets attributes and children for output.
      #
      # @param item [Hash] The output item.
      # @return [Array] An array with children and attributes.
      def split_output_item(item)
        item.partition {|k, _| [:title, :subtitle, :icon].include?(k) }.collect {|a| array_to_hash(a) }
      end

      # Fetches remote JSON resource.
      #
      # @param url [String] The URL to get.
      # @param params [Hash] The parameters to pass to the server.
      # @param json [Boolean] If the response is a JSON object.
      # @return [Hash] The server's response.
      def fetch_remote_resource(url, params, json = true)
        args = {query: params}
        args[:head] = {"accept" => "application/json"} if json
        response = EM::HttpRequest.new(url, {connect_timeout: 5}).get(args).response
        json ? Oj.load(response) : response
      end

      # Executes a command and returns its output.
      #
      # @param args [Array] The command to execute, with its arguments.
      # @return [String] The output of the command
      def execute_command(*args)
        rv = ""
        IO.popen(args) {|f| rv = f.read }
        rv
      end

      # Returns the current debug mode.
      #
      # @return [Boolean|NilClass] The current debug mode.
      def debug_mode
        mode = ENV["PINCERNA_DEBUG"] || @debug
        !mode.nil? ? mode.to_sym : nil
      end
  end
end
