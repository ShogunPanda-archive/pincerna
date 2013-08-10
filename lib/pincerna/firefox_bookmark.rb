# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Pincerna
  # Show the list of Firefox bookmarks.
  class FirefoxBookmark < Bookmark
    # The queries to obtain the bookmarks
    QUERIES = [
      "SELECT b.title, p.url, b.parent FROM moz_bookmarks b, moz_places p WHERE b.type=1 AND b.fk=p.id",
      "SELECT b.title, b.id, b.parent FROM moz_bookmarks b WHERE b.type=2"
    ]

    # The icon to show for each feedback item.
    ICON = Pincerna::Base::ROOT + "/images/firefox.png"

    # Gets the list of Chrome Bookmarks.
    def get_bookmarks
      path = Dir.glob(File.expand_path("~/Library/Application Support/Firefox/Profiles") + "/*.default").first
      data = execute_command("/usr/bin/sqlite3", "-echo", "#{path}/places.sqlite", QUERIES.join("; "))

      if !data.empty? then
        @folders = {}
        parse_bookmarks_data(data)
        build_paths
      end
    end

    private
      # Parses bookmarks data.
      #
      # @param data [String] The data to parse.
      def parse_bookmarks_data(data)
        data = StringScanner.new(data)
        data.skip_until(/\n/) # Discard the first line

        # While we're still in the first query, look for bookmarks
        while data.exist?(/#{QUERIES.last}/) do
          line = data.scan_until(/\n/).strip
          break if line == QUERIES.last
          add_bookmark(*restrict_array(line.split("|"), 3))
        end

        # Now look for folder
        while !data.eos? do
          line = data.scan_until(/\n/).strip
          add_folder(*restrict_array(line.split("|"), 3))
        end
      end

      # Builds the paths of the bookmarks.
      def build_paths
        @bookmarks.collect! do |bookmark|
          bookmark[:path] = build_path(bookmark[:path].to_i).reverse.join(" \u2192 ")
          bookmark
        end
      end

      # Builds the full path of a folder.
      #
      # @param id [Fixnum] The id of the folder.
      # @return [String] The path of the folder.
      def build_path(id)
        folder = @folders[id]
        folder ? [folder[0]] + build_path(folder[1]).compact : []
      end

      # Adds a folder to the list.
      #
      # @param title [String] The name of the folder.
      # @param id [String] The id of the folder.
      # @param parent [String] The id of the parent folder.
      def add_folder(title, id, parent)
        @folders[id.to_i] = [title, parent.to_i] if !title.empty?
      end

      # Restrict array making sure it does not exceed a length.
      #
      # @param array [Array] The array to restrict.
      # @param length [Fixnum] The maximum allowed length.
      # @return [Array] The restricted array.
      def restrict_array(array, len)
        array[0] = "#{array.shift}|#{array[0]}" while array.length > len
        array
      end
  end
end