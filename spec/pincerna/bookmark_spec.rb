# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Pincerna::Bookmark do
  subject { Pincerna::Bookmark.new("QUERY", "yml") }

  describe "#perform_filtering" do
    before(:each) do
      allow(subject).to receive(:read_bookmarks) {
        subject.instance_variable_set(:@bookmarks, [
          {name: "NAME 1", url: "URL 1", path: " \u2192 Barra dei Preferiti \u2192 FOLDER 1 \u2192 FOLDER 2"},
          {name: "2", url: "2", path: " \u2192 Barra dei Preferiti \u2192 FOLDER 1 \u2192 FOLDER 2"},
          {name: "NAME 3", url: "URL 3", path: " \u2192 Barra dei Preferiti \u2192 FOLDER 1"},
          {name: "NAME 3", url: "URL 3", path: " \u2192 Altri Preferiti"}
        ])
      }
    end

    it "should call #read_bookmarks" do
      expect(subject).to receive(:read_bookmarks)
      subject.perform_filtering("1")
    end

    it "should filter by query and sort correctly" do
      expect(subject.perform_filtering("")).to eq([
        {name: "2", url: "2", path: " \u2192 Barra dei Preferiti \u2192 FOLDER 1 \u2192 FOLDER 2"},
        {name: "NAME 1", url: "URL 1", path: " \u2192 Barra dei Preferiti \u2192 FOLDER 1 \u2192 FOLDER 2"},
        {name: "NAME 3", url: "URL 3", path: " \u2192 Altri Preferiti"},
        {name: "NAME 3", url: "URL 3", path: " \u2192 Barra dei Preferiti \u2192 FOLDER 1"}
      ])

      expect(subject.perform_filtering("NAME")).to eq([
        {name: "NAME 1", url: "URL 1", path: " \u2192 Barra dei Preferiti \u2192 FOLDER 1 \u2192 FOLDER 2"},
        {name: "NAME 3", url: "URL 3", path: " \u2192 Altri Preferiti"},
        {name: "NAME 3", url: "URL 3", path: " \u2192 Barra dei Preferiti \u2192 FOLDER 1"}
      ])

      expect(subject.perform_filtering("2")).to eq([{name: "2", url: "2", path: " \u2192 Barra dei Preferiti \u2192 FOLDER 1 \u2192 FOLDER 2"}])

      expect(subject.perform_filtering("3")).to eq([])
    end
  end

  describe "#read_bookmarks" do
    it "should abort with a warning" do
      expect { subject.read_bookmarks }.to raise_error(::ArgumentError)
    end
  end

  describe "#process_results" do
    it "should correctly prepare results" do
      expect(subject.process_results([{name: "TITLE", url: "URL"}])).to eq([{title: "TITLE", arg: "URL", subtitle: "Action this item to open the URL in the browser ...", icon: Pincerna::Bookmark::ICON}])
      expect(subject.process_results([{name: "TITLE", url: "URL", path: "PATH"}])).to eq([{title: "TITLE", arg: "URL", subtitle: "PATH", icon: Pincerna::Bookmark::ICON}])
    end
  end
end