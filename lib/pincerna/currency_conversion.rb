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
      (?<value>([+-]?)(\d+)([.,]\d+)?)
      \s
      (?<from>[a-z]{3})
      \s+
      (to\s+)?
      (?<to>[a-z]{3})
      (?<rate>\swith\srate)?
    $/mix

    # Relevant groups in the match.
    RELEVANT_MATCHES = {
      "value" => ->(context, value){ context.round_float(value.gsub(",", ".").to_f) },
      "from" => ->(_, value) { value.upcase },
      "to" => ->(_, value) { value.upcase },
      "rate" => ->(_, value) { !value.nil? } # If show conversion rate
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
      response = fetch_remote_resource("http://rate-exchange.appspot.com/currency", {q: value, from: from, to: to})
      {value: value, from: from, to: to, result: round_float(response["v"]), rate: round_float(response["rate"]), with_rate: with_rate}
    end

    # Processes items to obtain feedback items.
    #
    # @param results [Hash] The item to process.
    # @return [Array] The feedback items.
    def process_results(results)
      title = "%s %s = %s %s" % [format_float(results[:value]), results[:from], format_float(results[:result]), results[:to]]
      title << " (1 %s = %s %s)" % [results[:from], format_float(results[:rate]), results[:to]] if results[:with_rate]

      [{title: title, arg: format_float(results[:value]), subtitle: "Action this item to copy the converted amount on the clipboard.", icon: self.class::ICON}]
    end
  end
end
