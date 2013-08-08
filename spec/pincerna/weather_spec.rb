# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Pincerna::Weather do
  subject { Pincerna::Weather.new("QUERY", "yml") }

  describe "matching" do
    it "should match valid queries" do
      allow_any_instance_of(Pincerna::Weather).to receive(:perform_filtering) { |*args| args }
      allow_any_instance_of(Pincerna::Weather).to receive(:process_results) { |*args| args }

      expect(Pincerna::Weather.new("Campobasso", "yml").filter).to eq_as_yaml([["Campobasso", "c"]])
      expect(Pincerna::Weather.new("Campobasso in c", "yml").filter).to eq_as_yaml([["Campobasso", "c"]])
      expect(Pincerna::Weather.new("Campobasso in F", "yml").filter).to eq_as_yaml([["Campobasso", "f"]])
    end
  end

  describe "#perform_filtering", :vcr do
    before(:each) do
      allow(subject).to receive(:lookup_places).with("Campobasso") { |*args| [{woeid: 12345, name: "Campobasso, Molise, Italy"}] }
      allow(subject).to receive(:get_forecast).with([{woeid: 12345, name: "Campobasso, Molise, Italy"}], "c") { |*args|
        [{name: "Campobasso, Molise, Italy", image: "IMAGE", link: "LINK", current: {description: "TEXT", temperature: "29 C", wind: {speed: "29 kmh", direction: "W"}}, forecast: { description: "TEXT", high: "29 C", low: "13 C"}}]
      }
    end

    it "should get forecast" do
      expect(subject.perform_filtering("Campobasso", "c")).to eq([{name: "Campobasso, Molise, Italy", image: "IMAGE", link: "LINK", current: { description: "TEXT", temperature: "29 C", wind: {speed: "29 kmh", direction: "W"}}, forecast: { description: "TEXT", high: "29 C", low: "13 C"}}])
    end
  end

  describe "#process_results" do
    before(:each) do
      @value = [{name: "Campobasso, Molise, Italy", image: "IMAGE", link: "LINK", current: { description: "CURRENT", temperature: "29 C", wind: {speed: "29 kmh", direction: "W"}}, forecast: { description: "NEXT", high: "29 C", low: "13 C"}}]
    end

    it "should correctly prepare results" do
      expect(subject.process_results(@value)).to eq([{
        title: "Campobasso, Molise, Italy", arg: "LINK",
        subtitle: "29 C, Current, wind 29 kmh W - Next: 29 C / 13 C, NEXT",
        icon: "IMAGE"
      }])
    end
  end

  describe "#lookup_places", :vcr, :synchronous do
    it "should search for places" do
      expect(subject.lookup_places("Campobasso")).to eq([{woeid: 711892, name: "Campobasso, Molise, Italy"}])
      expect(subject.lookup_places("San Mateo")).to eq([{woeid: 2488142, name: "San Mateo, California, United States"}, {woeid: 2488139, name: "San Mateo, Putnam, Florida, United States"}, {woeid: 775977, name: "San Mateo, Sant Mateu, Castellon, Valencia, Spain"}, {woeid: 2488141, name: "San Mateo, Cibola, New Mexico, United States"}, {woeid: 2488150, name: "Jacksonville, Duval, Florida, United States"}])
      expect(subject.lookup_places("asdfghjkl")).to eq([])
    end

    it "should return an existing WOEID without making any request" do
      expect(subject.lookup_places("123")).to eq([{woeid: "123"}])
    end
  end

  describe "#get_forecast", vcr: true do
    before(:each) do
      @cache_dir = "/tmp/pincerna-weather"
      subject.instance_variable_set("@cache_dir", @cache_dir)
      FileUtils.rm_rf(@cache_dir)
    end

    after(:each) do
      FileUtils.rm_rf(@cache_dir)
    end

    it "should get correct forecasts" do
      expect(subject.get_forecast([{woeid: 711892, name: "Campobasso, Molise, Italy"}, {woeid: 2488142, name: "San Mateo, California, United States"}])).to eq([
        {
          woeid: 711892,
          name: "Campobasso, Molise, Italy",
          image: @cache_dir + "/weather/32.gif",
          link: "http://us.rd.yahoo.com/dailynews/rss/weather/Campobasso__IT/*http://weather.yahoo.com/forecast/ITXX0112_c.html",
          current: {description: "Sunny", temperature: "34 °C", wind: {speed: "1.61 km/h", direction: "W"}},
          forecast: {description: "Thunderstorms Early", high: "31 °C", low: "23 °C"}
        },
        {
          woeid: 2488142,
          name: "San Mateo, California, United States",
          image: @cache_dir + "/weather/26.gif",
          link: "http://us.rd.yahoo.com/dailynews/rss/weather/San_Mateo__CA/*http://weather.yahoo.com/forecast/USCA1005_c.html",
          current: {description: "Cloudy", temperature: "16 °C", wind: {speed: "9.66 km/h", direction: "W"}},
          forecast: {description: "AM Clouds/PM Sun", high: "21 °C", low: "14 °C"},
        }
      ])
    end

    it "should append name" do
      expect(subject.get_forecast([{woeid: 2488139}])).to eq([{
        woeid: 2488139,
        name: "San Mateo, FL, United States",
        image: @cache_dir + "/weather/30.gif",
        link: "http://us.rd.yahoo.com/dailynews/rss/weather/San_Mateo__FL/*http://weather.yahoo.com/forecast/USFL0538_c.html",
        current: {description: "Partly Cloudy", temperature: "31 °C", wind: {speed: "14.48 km/h", direction: "E"}},
        forecast: {description: "Scattered Thunderstorms", high: "32 °C", low: "24 °C"}
      }])
    end
  end

  describe "#get_wind_direction" do
    it "should correctly calculate directions" do
      results = [
        "N",
        "N", "NE", "NE", "NE", "NE", "E", "E", "E", "E", # 90
        "E", "SE", "SE", "SE", "SE", "S", "S", "S", "S", #180
        "S", "SW", "SW", "SW", "SW", "W", "W", "W", "W", # 240
        "W", "NW", "NW", "NW", "NW", "N", "N", "N", "N"
      ]

      37.times do |deg|
        expect(subject.get_wind_direction(deg * 10)).to eq(results[deg])
      end
    end
  end
end