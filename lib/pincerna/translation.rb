# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Pincerna
  # Translates text using Google Translate.
  class Translation < Base
    # The expression to match.
    MATCHER = /^
        (from\s+)?([a-z_-]{2,5})
        \s+
        (to\s+)?([a-z_-]{2,5})
        \s+
        (.+)
      $/mix

    # Relevant groups in the match.
    RELEVANT_MATCHES = {
      2 => Proc.new {|_, value| value }, # From
      4 => Proc.new {|_, value| value }, # To
      5 => Proc.new {|_, value| value.strip }, # Text
    }

    # The icon to show for each feedback item.
    ICON = Pincerna::Base::ROOT + "/images/translate.png"

    # Translates text using Google Translate.
    #
    # @param from [String] The code of the source language.
    # @param to [String] The code of the target language.
    # @param value [String] The text to translate.
    # @return [Hash|NilClass] The translation data or `nil` if the translation failed.
    def perform_filtering(from, to, value)
      rv = nil

      begin
        VCR.use_cassette('translations') do
          request = RestClient::Resource.new("http://translate.google.com.br/translate_a/t", :timeout => 5, :open_timeout => 5)
          response = JSON.parse(request.get({:accept => :json, :params => {:client => "p", :text => value, :sl => from, :tl => to, :multires => 1, :ssel => 0, :tsel => 0, :sc => 1, :ie => "UTF-8", :oe => "UTF-8"}}))
          
          # Parse results
          if response["dict"] then
            translations = response["dict"][0]["entry"].collect {|t| t["word"] }
            rv = {:main => translations.shift, :alternatives => translations}
          else
            translation = response["sentences"][0]["trans"]
            rv = {:main => translation} if translation != value
          end
        end
      rescue => e
        raise e
      end

      rv
    end

    # Processes items to obtain feedback items.
    #
    # @param results [Array] The items to process.
    # @return [Array] The feedback items.
    def process_results(results)
      alternatives = results[:alternatives] ? "Alternatives: #{results[:alternatives].join(", ")}" : "Action this item to copy the translation on the clipboard."
      [{:title => results[:main], :arg => results[:main], :subtitle => alternatives, :icon => self.class::ICON}]
    end
  end
end
