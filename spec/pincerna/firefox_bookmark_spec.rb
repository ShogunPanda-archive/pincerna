# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

require "spec_helper"

describe Pincerna::FirefoxBookmark do
  subject { Pincerna::FirefoxBookmark.new("QUERY", "yml") }

  describe "#firefox_bookmarks" do
    before(:each) do
      @sqlite = <<EOSQLITE
#{Pincerna::FirefoxBookmark::QUERIES.first}
NAME 1|URL 1|4
NAME 2|URL 2|4
NAME|3|URL 3|3
NAME 4|URL 4|2
#{Pincerna::FirefoxBookmark::QUERIES.last}
BookmarksBar|1|0
BookmarksMenu|2|0
FOLDER 1|3|1
FOLDER|2|4|3
EOSQLITE
    end

    it "should call sqlite4 to get latest bookmarks" do
      expect(Dir).to receive(:glob).with(File.expand_path("~/Library/Application Support/Firefox/Profiles") + "/*.default").and_return(["FIRST", "SECOND"])
      expect(subject).to receive(:execute_command).with("/usr/bin/sqlite3", "-echo", "FIRST/places.sqlite", Pincerna::FirefoxBookmark::QUERIES.join("; "))
      subject.read_bookmarks
    end

    it "should return the correct list of bookmarks" do
      expect(subject.instance_variable_set(:@bookmarks, []))
      allow(subject).to receive(:execute_command).and_return(@sqlite)
      subject.read_bookmarks
      expect(subject.instance_variable_get(:@bookmarks)).to eq([
        {name: "NAME 1", url: "URL 1", path: " \u2192 BookmarksBar \u2192 FOLDER 1 \u2192 FOLDER|2"},
        {name: "NAME 2", url: "URL 2", path: " \u2192 BookmarksBar \u2192 FOLDER 1 \u2192 FOLDER|2"},
        {name: "NAME|3", url: "URL 3", path: " \u2192 BookmarksBar \u2192 FOLDER 1"},
        {name: "NAME 4", url: "URL 4", path: " \u2192 BookmarksMenu"}
      ])
    end
  end
end