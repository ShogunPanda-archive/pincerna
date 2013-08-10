# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Pincerna::ChromeBookmark do
  subject { Pincerna::ChromeBookmark.new("QUERY", "yml") }

  describe "#Chrome_bookmarks" do
    before(:each) do
      @json = <<EOJSON
{
  "checksum": "",
  "roots": {
    "bookmark_bar": {
      "children": [
        {
          "children": [
            {
              "children": [
                {
                  "date_added": "13018920348983801",
                  "id": "1145",
                  "name": "NAME 1",
                  "type": "url",
                  "url": "URL 1"
                },
                {
                  "date_added": "13018920348983801",
                  "id": "1145",
                  "name": "NAME 2",
                  "type": "url",
                  "url": "URL 2"
                }
              ],
              "date_added": "13018920348874387",
              "date_modified": "13018920348996854",
              "id": "1087",
              "name": "FOLDER 2",
              "type": "folder"
            },
            {
              "date_added": "13018920348983801",
              "id": "1145",
              "name": "NAME 3",
              "type": "url",
              "url": "URL 3"
            }
          ],
          "date_added": "13018920348873174",
          "date_modified": "13018920348989347",
          "id": "1086",
          "name": "FOLDER 1",
          "type": "folder"
        }
      ],
      "date_added": "12980910274469592",
      "date_modified": "13005935882687426",
      "id": "1",
      "name": "Barra dei Preferiti",
      "type": "folder"
    },
    "other": {
      "children": [
        {
          "date_added": "13018920348983801",
          "id": "1145",
          "name": "NAME 4",
          "type": "url",
          "url": "URL 4"
        }
      ],
      "date_added": "12980910274469613",
      "date_modified": "13020577556062605",
      "id": "2",
      "name": "Altri Preferiti",
      "type": "folder"
    },
    "synced": {
      "children": [  ],
      "date_added": "12980910274469615",
      "date_modified": "0",
      "id": "3",
      "name": "Preferiti su disp. mobili",
      "type": "folder"
    }
  },
  "version": 1
}
EOJSON
    end

    it "should read the JSON file to get latest bookmarks" do
      expect(File).to receive(:read).with(File.expand_path("~/Library/Application Support/Google/Chrome/Default/Bookmarks")).and_return("{}")
      expect(Oj).to receive(:load).with("{}").and_return({"roots" => {}})
      subject.read_bookmarks
    end

    it "should return the correct list of bookmarks" do
      expect(subject.instance_variable_set(:@bookmarks, []))
      expect(File).to receive(:read).and_return(@json)
      subject.read_bookmarks
      expect(subject.instance_variable_get(:@bookmarks)).to eq([
        {name: "NAME 1", url: "URL 1", path: " \u2192 Barra dei Preferiti \u2192 FOLDER 1 \u2192 FOLDER 2"},
        {name: "NAME 2", url: "URL 2", path: " \u2192 Barra dei Preferiti \u2192 FOLDER 1 \u2192 FOLDER 2"},
        {name: "NAME 3", url: "URL 3", path: " \u2192 Barra dei Preferiti \u2192 FOLDER 1"},
        {name: "NAME 4", url: "URL 4", path: " \u2192 Altri Preferiti"}
      ])
    end
  end
end