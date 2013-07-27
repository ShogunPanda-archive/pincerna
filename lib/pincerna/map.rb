# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "cgi"

module Pincerna
  # Shows an address on Google Maps.
  class Map < Base
    # The icon to show for each feedback item.
    ICON = Pincerna::Base::ROOT + "/images/map.png"

    # Filters a query.
    #
    # @param query [String] An address to show on Google Maps.
    # @return [Array] A list of items to process.
    def perform_filtering(query)
      {query: query}
    end

    # Processes items to obtain feedback items.
    #
    # @param results [Array] The items to process.
    # @return [Array] The feedback items.
    def process_results(results)
      type = results[:query] =~ /((-?)\d+(\.\d+)?)\s*,\s*((-?)\d+(\.\d+)?)/ ? "coordinates" : "address"
      [{title: "View #{type} on Google Maps", arg: CGI.escape(results[:query]), subtitle: "Action this item to open Google Maps on the browser.", icon: self.class::ICON}]
    end
  end
end
