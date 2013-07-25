# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

# A bunch of useful Alfred 2 workflows.
module Pincerna
  # Base class for all filter.
  class Base
    ROOT = File.expand_path(File.dirname(__FILE__) + "/../../")

    # The expression to match.
    MATCHER = /^(.*)$/i

    # Relevant groups in the match.
    RELEVANT_MATCHES = {
      1 => Proc.new {|_, value| value }, # The full query
    }

    # Executes a filtering query.
    #
    # @param type [Symbol] The type of the query.
    # @param query [String] The argument of the query.
    # @return [String] The result of the query.
    def self.execute!(type, query)
      case type
        when :unit, :c then Pincerna::UnitConversion.new(query).filter
        when :currency, :cc then Pincerna::CurrencyConversion.new(query).filter
        when :translate, :t then Pincerna::Translation.new(query).filter
        when :map, :m then Pincerna::Map.new(query).filter
        when :weather, :forecast then Pincerna::Weather.new(query).filter
        when :ip then Pincerna::Ip.new(query).filter
        when :vpn then Pincerna::Vpn.new(query).filter
        else ""
      end
    end

    # Creates a new query.
    #
    # @param query [String] The argument of the query.
    def initialize(query)
      @query = query.strip
      @feedback_items = []
    end

    # Filters a query.
    #
    # @return [String] The feedback items of the query, formatted as XML.
    def filter
      relevant = self.class::RELEVANT_MATCHES

      # Match
      matches = self.class::MATCHER.match(@query)

      if matches then
        # Get relevant groups and process them
        args = relevant.keys.sort.collect {|index| 
          converter = relevant[index]
          converter.call(self, matches[index]) 
        }

        # Now perform the operation
        results = perform_filtering(*args)

        # Show results if appropriate
        process_results(results).each {|r| add_feedback_item(r) } if results
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
      xml = Builder::XmlMarkup.new
      xml.items do |root|
        @feedback_items.each do |f|
          childs, attributes = f.partition {|k, _| [:title, :subtitle, :icon].include?(k) }.collect {|a| array_to_hash(a) }

          root.item(attributes) do |item|
            childs.each { |name, value| item.__send__(name, value) }
          end
        end
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

    # Rounds a float to a certain precision.
    #
    # @param value [Float] The value to convert.
    # @param precision [Fixnum] The precision to use.
    # @return [Float] The rounded value.
    def round_float(value, precision = 3)
      factor = 10**precision
      (value * factor).round.to_f / factor
    end
  end
end
