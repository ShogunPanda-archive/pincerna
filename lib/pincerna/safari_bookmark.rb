# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

module Pincerna
  # Show the list of Safari bookmarks.
  class SafariBookmark < Bookmark
    # The icon to show for each feedback item.
    ICON = Pincerna::Base::ROOT + "/images/safari.png"

    # The file with bookmarks data.
    BOOKMARKS_DATA = File.expand_path("~/Library/Safari/Bookmarks.plist")

    # Reads the list of Safari Bookmarks.
    def read_bookmarks
      data = execute_command("/usr/bin/plutil", "-convert", "xml1", "-o", "-", BOOKMARKS_DATA)

      if data && !data.empty? then
        Plist.parse_xml(data)["Children"].each do |children|
          scan_folder(children, "")
        end
      end
    end

    private
      # Scans a folder of bookmarks.
      #
      # @param node [Hash] The directory to visit.
      # @param path [String] The path of this node.
      def scan_folder(node, path)
        path += " #{SEPARATOR} #{node["Title"]}"

        (node["Children"] || []).each do |children|
          children["WebBookmarkType"] == "WebBookmarkTypeLeaf" ? add_bookmark(children["URIDictionary"]["title"], children["URLString"], path) : scan_folder(children, path)
        end
      end
  end
end