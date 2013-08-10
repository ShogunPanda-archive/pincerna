# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Pincerna
  # Show the list of Chrome bookmarks.
  class ChromeBookmark < Bookmark
    # The icon to show for each feedback item.
    ICON = Pincerna::Base::ROOT + "/images/chrome.png"

    # Reads the list of Chrome Bookmarks.
    def read_bookmarks
      data = File.read(File.expand_path("~/Library/Application Support/Google/Chrome/Default/Bookmarks")) rescue nil

      if data then
        Oj.load(data)["roots"].each do |_, root|
          scan_folder(root, "") if root.is_a?(Hash)
        end
      end
    end

    private
      # Scans a folder of bookmarks.
      #
      # @param node [Hash] The directory to visit.
      # @param path [String] The path of this node.
      def scan_folder(node, path)
        path += " \u2192 #{node["name"]}"

        node["children"].each do |children|
          children["type"] == "url" ? add_bookmark(children["name"], children["url"], path) : scan_folder(children, path)
        end
      end
  end
end