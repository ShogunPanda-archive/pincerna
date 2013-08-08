# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Pincerna
  # Show the list of Safari bookmarks.
  class Bookmark < Base
    # The expression to match.
    MATCHER = /^(?<all>.*)$/i

    # The icon to show for each feedback item.
    # TODO@SP: Change this.
    ICON = Pincerna::Base::ROOT + "/images/network.png"

    # Processes items to obtain feedback items.
    #
    # @param results [Array] The items to process.
    # @return [Array] The feedback items.
    def process_results(results)
      results.collect do |result|
        subtitle = result[:path] || "Action this item to open the URL in the browser ..."
        {title: result[:name], arg: result[:url], subtitle: subtitle, icon: self.class::ICON}
      end
    end
  end
end

require "pincerna/safari_bookmark"
require "pincerna/firefox_bookmark"
require "pincerna/chrome_bookmark"