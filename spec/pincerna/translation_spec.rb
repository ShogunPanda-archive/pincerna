# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Pincerna::Translation do
  subject { Pincerna::Translation.new("QUERY", "yml") }

  describe "matching" do
    it "should match valid queries" do
      allow_any_instance_of(Pincerna::Translation).to receive(:perform_filtering) { |*args| args }
      allow_any_instance_of(Pincerna::Translation).to receive(:process_results) { |*args| args }

      expect(Pincerna::Translation.new("zh-cn en FOO", "yml").filter).to eq_as_yaml([["zh-cn", "en", "FOO"]])
      expect(Pincerna::Translation.new("IT to EN FOO", "yml").filter).to eq_as_yaml([["it", "en", "FOO"]])
    end

    it "should not match invalid queries" do
      expect_any_instance_of(Pincerna::Translation).not_to receive(:perform_filtering)
      expect_any_instance_of(Pincerna::Translation).not_to receive(:process_results)

      expect(Pincerna::Translation.new("abc", "yml").filter).to eq_as_yaml([])
    end
  end

  describe "#perform_filtering", :vcr, :synchronous do
    before(:each) do
      cache = Object.new
      allow(cache).to receive(:use).and_yield
      allow(Pincerna::Cache).to receive(:instance).and_return(cache)
    end

    it "should query Google Translate for single words" do
      expect(subject.perform_filtering("it", "en", "Ciao")).to eq({main: "Hello!", alternatives: ["Hi!", "Bye-Bye!", "Bye!", "So long!", "Cheerio!", "Hallo!", "Hullo!"]})
    end

    it "should query Google Translate for sentences, returning no alternatives" do
      expect(subject.perform_filtering("it", "en", "Ciao, come stai?")).to eq({main: "Hello, how are you?"})
    end

    it "should default from English to the given language when only one is present" do
      expect(subject.perform_filtering("it", nil, "do")).to eq({main: "fare", alternatives: ["eseguire", "compiere", "agire", "operare", "comportarsi", "commettere", "stare", "bastare", "causare", "finire", "andare bene", "andar bene", "portare a termine", "procurare", "imbrogliare", "ingannare", "passarsela", "visitare", "combinare", "concludere"]})
    end
  end

  describe "#process_results" do
    it "should correctly prepare results" do
      expect(subject.process_results({main: "fare", alternatives: ["eseguire", "compiere"]})).to eq([{title: "fare", arg: "fare", subtitle: "Alternatives: eseguire, compiere", icon: Pincerna::Translation::ICON}])
      expect(subject.process_results({main: "Hello, how are you?"})).to eq([{title: "Hello, how are you?", arg: "Hello, how are you?", subtitle: "Action this item to copy the translation on the clipboard.", icon: Pincerna::Translation::ICON}])
    end
  end
end