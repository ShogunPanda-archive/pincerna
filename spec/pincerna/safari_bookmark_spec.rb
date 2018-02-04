# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

require "spec_helper"

describe Pincerna::SafariBookmark do
  subject { Pincerna::SafariBookmark.new("QUERY", "yml") }

  describe "#read_bookmarks" do
    before(:each) do
      @plutil = <<EOPLUTIL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Children</key>
    <array>
      <dict>
        <key>Title</key>
        <string>History</string>
        <key>WebBookmarkIdentifier</key>
        <string>History</string>
        <key>WebBookmarkType</key>
        <string>WebBookmarkTypeProxy</string>
        <key>WebBookmarkUUID</key>
        <string>CCC</string>
      </dict>
      <dict>
        <key>Children</key>
        <array>
          <dict>
            <key>Children</key>
            <array>
              <dict>
                <key>Children</key>
                <array>
                  <dict>
                    <key>Sync</key>
                    <dict>
                      <key>Key</key>
                      <string>"C=AAA"</string>
                      <key>ServerID</key>
                      <string>AAA</string>
                    </dict>
                    <key>URIDictionary</key>
                    <dict>
                      <key>title</key>
                      <string>NAME 1</string>
                    </dict>
                    <key>URLString</key>
                    <string>URL 1</string>
                    <key>WebBookmarkType</key>
                    <string>WebBookmarkTypeLeaf</string>
                    <key>WebBookmarkUUID</key>
                    <string>AAA</string>
                  </dict>

                  <dict>
                    <key>Sync</key>
                    <dict>
                      <key>Key</key>
                      <string>"C=AAA"</string>
                      <key>ServerID</key>
                      <string>AAA</string>
                    </dict>
                    <key>URIDictionary</key>
                    <dict>
                      <key>title</key>
                      <string>NAME 2</string>
                    </dict>
                    <key>URLString</key>
                    <string>URL 2</string>
                    <key>WebBookmarkType</key>
                    <string>WebBookmarkTypeLeaf</string>
                    <key>WebBookmarkUUID</key>
                    <string>AAA</string>
                  </dict>

                </array>
                <key>Sync</key>
                <dict>
                  <key>Data</key>
                  <data>CCC</data>
                  <key>Key</key>
                  <string>AAA</string>
                  <key>ServerID</key>
                  <string>BBB</string>
                </dict>
                <key>Title</key>
                <string>FOLDER 2</string>
                <key>WebBookmarkType</key>
                <string>WebBookmarkTypeList</string>
                <key>WebBookmarkUUID</key>
                <string>CCC</string>
              </dict>

              <dict>
                <key>Sync</key>
                <dict>
                  <key>Key</key>
                  <string>"C=AAA"</string>
                  <key>ServerID</key>
                  <string>AAA</string>
                </dict>
                <key>URIDictionary</key>
                <dict>
                  <key>title</key>
                  <string>NAME 3</string>
                </dict>
                <key>URLString</key>
                <string>URL 3</string>
                <key>WebBookmarkType</key>
                <string>WebBookmarkTypeLeaf</string>
                <key>WebBookmarkUUID</key>
                <string>AAA</string>
              </dict>
            </array>
            <key>Sync</key>
            <dict>
              <key>Data</key>
              <data>DDD</data>
              <key>Key</key>
              <string>CCC</string>
              <key>ServerID</key>
              <string>DDD</string>
            </dict>
            <key>Title</key>
            <string>FOLDER 1</string>
            <key>WebBookmarkType</key>
            <string>WebBookmarkTypeList</string>
            <key>WebBookmarkUUID</key>
            <string>AAA</string>
          </dict>
        </array>
        <key>Sync</key>
        <dict>
          <key>ServerID</key>
          <string>CCC</string>
        </dict>
        <key>Title</key>
        <string>BookmarksBar</string>
        <key>WebBookmarkType</key>
        <string>WebBookmarkTypeList</string>
        <key>WebBookmarkUUID</key>
        <string>DDD</string>
      </dict>
      <dict>
        <key>Sync</key>
        <dict>
          <key>ServerID</key>
          <string>CCC</string>
        </dict>
        <key>Title</key>
        <string>BookmarksMenu</string>
        <key>WebBookmarkType</key>
        <string>WebBookmarkTypeList</string>
        <key>WebBookmarkUUID</key>
        <string>DDD</string>
        <key>Children</key>
        <array>
          <dict>
            <key>Sync</key>
            <dict>
              <key>Key</key>
              <string>"C=AAA"</string>
              <key>ServerID</key>
              <string>AAA</string>
            </dict>
            <key>URIDictionary</key>
            <dict>
              <key>title</key>
              <string>NAME 4</string>
            </dict>
            <key>URLString</key>
            <string>URL 4</string>
            <key>WebBookmarkType</key>
            <string>WebBookmarkTypeLeaf</string>
            <key>WebBookmarkUUID</key>
            <string>AAA</string>
          </dict>
        </array>
      </dict>
      <dict>
        <key>ShouldOmitFromUI</key>
        <true/>
        <key>Sync</key>
        <dict>
          <key>ServerID</key>
          <string>CCC</string>
        </dict>
        <key>Title</key>
        <string>com.apple.ReadingList</string>
        <key>WebBookmarkType</key>
        <string>WebBookmarkTypeList</string>
        <key>WebBookmarkUUID</key>
        <string>DDD</string>
      </dict>
    </array>
    <key>Sync</key>
    <dict>
      <key>ServerData</key>
      <data>BBB</data>
    </dict>
    <key>Title</key>
    <string></string>
    <key>WebBookmarkFileVersion</key>
    <integer>1</integer>
    <key>WebBookmarkType</key>
    <string>WebBookmarkTypeList</string>
    <key>WebBookmarkUUID</key>
    <string>AAA</string>
  </dict>
</plist>
EOPLUTIL
    end

    it "should call plutil to get latest bookmarks" do
      expect(subject).to receive(:execute_command).with("/usr/bin/plutil", "-convert", "xml1", "-o", "-", File.expand_path("~/Library/Safari/Bookmarks.plist"))
      subject.read_bookmarks
    end

    it "should return the correct list of bookmarks" do
      expect(subject.instance_variable_set(:@bookmarks, []))
      allow(subject).to receive(:execute_command).and_return(@plutil)
      subject.read_bookmarks
      expect(subject.instance_variable_get(:@bookmarks)).to eq([
        {name: "NAME 1", url: "URL 1", path: " \u2192 BookmarksBar \u2192 FOLDER 1 \u2192 FOLDER 2"},
        {name: "NAME 2", url: "URL 2", path: " \u2192 BookmarksBar \u2192 FOLDER 1 \u2192 FOLDER 2"},
        {name: "NAME 3", url: "URL 3", path: " \u2192 BookmarksBar \u2192 FOLDER 1"},
        {name: "NAME 4", url: "URL 4", path: " \u2192 BookmarksMenu"}
      ])
    end
  end
end