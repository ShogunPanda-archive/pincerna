# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Pincerna
  # Converts a value from a currency to another.
  class CurrencyConversion < Base
    # The expression to match.
    MATCHER = /^
      (([+-]?)(\d+)([.,]\d+)?) # Currency
      \s
      ([a-z]{3}) # From value
      \s+
      (to\s+)?
      ([a-z]{3}) # To value
      (\swith\srate)? # Optional
    $/mix

    # Relevant groups in the match.
    RELEVANT_MATCHES = {
      1 => Proc.new {|context, value| context.round_float(value.gsub(",", ".").to_f) }, # Value
      5 => Proc.new {|_, value| value.upcase }, # Origin currency
      7 => Proc.new {|_, value| value.upcase }, # Target currency
      8 => Proc.new {|_, value| !value.nil? } # If show rate
    }

    # The icon to show for each feedback item.
    ICON = Pincerna::Base::ROOT + "/images/currency.png"

    # Converts a value from a currency to another.
    #
    # @param value [Float] The value to convert.
    # @param from [String] The origin currency.
    # @param to [String] The target currency.
    # @param with_rate [Boolean] If to return the conversion rate in the results.
    # @return [Hash|NilClass] The converted data or `nil` if the conversion failed.
    def perform_filtering(value, from, to, with_rate)
      rv = nil

      begin
        request = RestClient::Resource.new("http://rate-exchange.appspot.com/currency", :timeout => 5, :open_timeout => 5)
        response = JSON.parse(request.get({:accept => :json, :params => {:q => value, :from => from, :to => to}}))
        rv = {:value => value, :from => from, :to => to, :result => round_float(response["v"]), :rate => round_float(response["rate"]), :with_rate => with_rate}
      rescue
      end

      rv
    end

    # Processes items to obtain feedback items.
    #
    # @param results [Hash] The item to process.
    # @return [Array] The feedback items.
    def process_results(results)
      title = "%0.3f #{results[:from]} = %0.3f #{results[:to]}" % [results[:value], results[:result]]
      title << " (1 #{results[:from]} = %0.3f #{results[:to]})" % results[:rate] if results[:with_rate]

      [{:title => title, :arg => "%0.3f" % results[:result], :subtitle => "Action this item to copy the converted amount on the clipboard.", :icon => self.class::ICON}]
    end
  end
end
