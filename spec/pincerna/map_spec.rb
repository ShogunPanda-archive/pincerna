# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Pincerna::Map do
  subject { Pincerna::Map.new("QUERY", "yml") }

  describe "#perform_filtering" do
    it "should simply return the query" do
      expect(subject.perform_filtering("QUERY")).to eq({query: "QUERY"})
    end
  end

  describe "#process_results" do
    it "should correctly prepare results" do
      expect(subject.process_results({query: "San Mateo, CA"})).to eq([{title: "View location on Google Maps", arg: "San+Mateo%2C+CA", subtitle: "Action this item to open Google Maps on the browser.", icon: Pincerna::Map::ICON}])
      expect(subject.process_results({query: "-123.45,67.89"})).to eq([{title: "View coordinates on Google Maps", arg: "-123.45%2C67.89", subtitle: "Action this item to open Google Maps on the browser.", icon: Pincerna::Map::ICON}])
    end
  end
end