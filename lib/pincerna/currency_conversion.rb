# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

module Pincerna
  # Converts a value from a currency to another.
  class CurrencyConversion < Base
    # The expression to match.
    MATCHER = /^
      (?<value>([+-]?)(\d+)([.,]\d+)?)
      \s
      (?<from>\S{1,3})
      \s+
      (to\s+)?
      (?<to>\S{1,3})
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

    # The URL of the webservice.
    URL = "http://rate-exchange.appspot.com/currency"

    # A list of symbols and their associated ISO codes
    SYMBOLS = {
      "Lek" => "ALL",
      "؋" => "AFN",
      "$" => "USD",
      "ƒ" => "ANG",
      "ман" => "AZN",
      "p." => "BYR",
      "BZ$" => "BZD",
      "$b" => "BOB",
      "KM" => "BAM",
      "P" => "BWP",
      "лв" => "UZS",
      "R$" => "BRL",
      "៛" => "KHR",
      "¥" => "JPY",
      "₡" => "CRC",
      "kn" => "HRK",
      "₱" => "PHP",
      "Kč" => "CZK",
      "kr" => "SEK",
      "RD$" => "DOP",
      "£" => "GBP",
      "€" => "EUR",
      "¢" => "GHC",
      "Q" => "GTQ",
      "L" => "HNL",
      "Ft" => "HUF",
      "" => "TRY",
      "Rp" => "IDR",
      "﷼" => "YER",
      "₪" => "ILS",
      "J$" => "JMD",
      "₩" => "KRW",
      "₭" => "LAK",
      "Ls" => "LVL",
      "Lt" => "LTL",
      "ден" => "MKD",
      "RM" => "MYR",
      "₨" => "LKR",
      "₮" => "MNT",
      "MT" => "MZN",
      "C$" => "NIO",
      "₦" => "NGN",
      "B/." => "PAB",
      "Gs" => "PYG",
      "S/." => "PEN",
      "zł" => "PLN",
      "lei" => "RON",
      "руб" => "RUB",
      "Дин." => "RSD",
      "S" => "SOS",
      "R" => "ZAR",
      "CHF" => "CHF",
      "NT$" => "TWD",
      "฿" => "THB",
      "TT$" => "TTD",
      "₤" => "TRL",
      "₴" => "UAH",
      "$U" => "UYU",
      "Bs" => "VEF",
      "₫" => "VND",
      "Z$" => "ZWD"
    }

    # Converts a value from a currency to another.
    #
    # @param value [Float] The value to convert.
    # @param from [String] The origin currency.
    # @param to [String] The target currency.
    # @param with_rate [Boolean] If to return the conversion rate in the results.
    # @return [Hash|NilClass] The converted data or `nil` if the conversion failed.
    def perform_filtering(value, from, to, with_rate)
      from = replace_symbol(from)
      to = replace_symbol(to)
      response = fetch_remote_resource(URL, {q: value, from: from, to: to})
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

    private
      # Replaces a currency symbol with its corresponding ISO code.
      #
      # @param symbol [String] The symbol to replace.
      # @return [String] The corresponding code. If none is found, the original symbol is returned.
      def replace_symbol(symbol)
        SYMBOLS.fetch(symbol, symbol)
      end
  end
end
