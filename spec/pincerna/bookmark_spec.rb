# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Pincerna::Bookmark do
  subject { Pincerna::Bookmark.new("QUERY", "yml") }

  describe "#process_results" do
    it "should correctly prepare results" do
      expect(subject.process_results([{name: "TITLE", url: "URL"}])).to eq([{title: "TITLE", arg: "URL", subtitle: "Action this item to open the URL in the browser ...", icon: Pincerna::Bookmark::ICON}])
      expect(subject.process_results([{name: "TITLE", url: "URL", path: "PATH"}])).to eq([{title: "TITLE", arg: "URL", subtitle: "PATH", icon: Pincerna::Bookmark::ICON}])
    end
  end
end