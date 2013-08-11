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
    ICON = Pincerna::Base::ROOT + "/images/safari.png"

    # Reads the list of Chrome Bookmarks.
    #
    # @param query [Array] A query to match against bookmarks names.
    # @return [Array] A list of boomarks.
    def perform_filtering(query)
      Pincerna::Cache.instance.use("bookmarks:#{self.class.to_s}", Pincerna::Cache::EXPIRATIONS[:short]) do
        # Get bookmarks and then only keep valid ones
        @bookmarks = []
        read_bookmarks
        filter_and_sort(@bookmarks, query)
      end
    end

    # Processes items to obtain feedback items.
    #
    # @param results [Array] The items to process.
    # @return [Array] The feedback items.
    def process_results(results)
      results.collect do |result|
        subtitle = result[:path] ? result[:path].gsub(/^\s\u2192 /, "") : "Action this item to open the URL in the browser ..."
        {title: result[:name], arg: result[:url], subtitle: subtitle, icon: ICON}
      end
    end

    # Reads the list of bookmarks.
    def read_bookmarks
      raise ArgumentError.new("Must be overriden by subclasses.")
    end

    private
      # Filters and sorts bookmarks.
      #
      # @param bookmarks [Array] The bookmarks list.
      # @param query [String] The query to filter.
      def filter_and_sort(bookmarks, query)
        # Filtering
        matcher = !query.empty? ? /^#{Regexp.escape(query.downcase)}/i : nil
        bookmarks = bookmarks.select {|bookmark| bookmark[:name] =~ matcher } if matcher

        # Sorting
        bookmarks.sort {|first, second|
          cmp = first[:name] <=> second[:name]
          cmp = first[:path] <=> second[:path] if cmp == 0
          cmp
        }
      end

    protected
      # Adds a bookmarks to the list.
      #
      # @param title [String] The title of the bookmark.
      # @param url [String] The URL of the bookmark.
      # @param path [String] The id of the parent folder.
      def add_bookmark(title, url, path)
        @bookmarks << {name: title, url: url, path: path} if title && !title.empty? && url && !url.empty? && url !~ /^javascript:/
      end
  end
end

require "pincerna/safari_bookmark"
require "pincerna/firefox_bookmark"
require "pincerna/chrome_bookmark"