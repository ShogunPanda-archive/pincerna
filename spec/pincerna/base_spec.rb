# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"
require "yaml"
require "pincerna/map"

describe Pincerna::Base do
  subject { Pincerna::Base.new("QUERY", "yml") }

  let(:reference_xml) {
    <<EOXML
<?xml version="1.0"?>
<items>
  <item first="FIRST" second="SECOND" third="THIRD">
    <title>TITLE 1</title>
    <subtitle>SUBTITLE 1</subtitle>
    <icon>ICON 1</icon>
  </item>
  <item fourth="FOURTH" fifth="FIFTH" sixth="SIXTH">
    <title>TITLE 2</title>
    <subtitle>SUBTITLE 2</subtitle>
    <icon>ICON 2</icon>
  </item>
</items>
EOXML

  }
  describe ".execute" do
    it "should find relevant class" do
      expect(Pincerna::Map).to receive(:new).and_call_original
      expect(Pincerna::Base.execute!("map", "QUERY"))
    end

    it "should create a query and then filter" do
      query = ::Object.new
      expect(query).to receive(:filter).and_return("FILTER")
      expect(Pincerna::Map).to receive(:new).with("QUERY", "FORMAT", "DEBUG").and_return(query)
      expect(Pincerna::Base.execute!("map", "QUERY", "FORMAT", "DEBUG"))
    end

    it "should not fail if a matching class is not found" do
      expect { expect(Pincerna::Base.execute!("invalid", "QUERY")) }.not_to raise_error
    end
  end

  describe "#initalize" do
    it "should initialize correct attributes" do
      expect(subject.instance_variable_get(:@query)).to eq("QUERY")
      expect(subject.instance_variable_get(:@cache_dir)).to eq(::File.expand_path("~/Library/Caches/com.runningwithcrayons.Alfred-2/Workflow Data/it.cowtech.pincerna"))
      expect(subject.instance_variable_get(:@feedback_items)).to eq([])
      expect(subject.format).to eq(:yml)

    end

    it "should save debug mode" do
      reference = Pincerna::Base.new("QUERY", "yml", "DEBUG")
      expect(reference.instance_variable_get(:@debug)).to eq("DEBUG")
    end

    it "should save format" do
      reference = Pincerna::Base.new("QUERY", "yml", "DEBUG")
      expect(reference.format).to eq(:yml)
      expect(reference.format_content_type).to eq("text/x-yaml")

      reference = Pincerna::Base.new("QUERY", "yaml", "DEBUG")
      expect(reference.format).to eq(:yml)
      expect(reference.format_content_type).to eq("text/x-yaml")

      reference = Pincerna::Base.new("QUERY", "FOO", "DEBUG")
      expect(reference.format).to eq(:xml)
      expect(reference.format_content_type).to eq("text/xml")
    end
  end

  describe "#filter" do
    before(:each) do
      allow(subject).to receive(:perform_filtering).with("QUERY").and_return([{query: "query"}])
      allow(subject).to receive(:process_results).with([{query: "query"}]).and_return([{title: "QUERY", arg: "query"}])
    end

    it "match the query, filter it and then process" do
      expect(subject.filter).to eq_as_yaml([{title: "QUERY", arg: "query"}])
    end

    it "should return an array if a failure occurs" do
      allow(subject).to receive(:perform_filtering).and_raise(::ArgumentError)
      allow(subject).to receive(:process_results).with([]).and_return([])
      expect(subject.filter).to eq_as_yaml([])
    end
  end

  describe "#perform_filtering" do
    it "should abort with a warning" do
      expect { subject.perform_filtering([]) }.to raise_error(::ArgumentError)
    end
  end

  describe "#process_results" do
    it "should abort with a warning" do
      expect { subject.process_results([]) }.to raise_error(::ArgumentError)
    end
  end

  describe "#add_feedback_item" do
    before(:each) do
      subject.add_feedback_item("ITEM 1")
      subject.add_feedback_item("ITEM 2")
    end

    it "should append to the internal items list" do
      expect(subject.instance_variable_get(:@feedback_items)).to eq(["ITEM 1", "ITEM 2"])
    end
  end

  describe "#output_feedback" do
    describe "when not in debug" do
      before(:each) do
        subject.add_feedback_item({title: "TITLE 1", subtitle: "SUBTITLE 1", icon: "ICON 1", first: "FIRST", second: "SECOND", third: "THIRD"})
        subject.add_feedback_item({title: "TITLE 2", subtitle: "SUBTITLE 2", icon: "ICON 2", fourth: "FOURTH", fifth: "FIFTH", sixth: "SIXTH"})
        allow(subject).to receive(:format).and_return(:xml)
        allow(subject).to receive(:debug_mode).and_return(nil)
      end

      it "should return items as XML" do
        expect(subject.output_feedback.gsub(/\s/, "")).to eq(reference_xml.gsub(/\s/, ""))
      end
    end

    describe "when in debug" do
      before(:each) do
        subject.add_feedback_item("ITEM 1")
        subject.add_feedback_item("ITEM 2")
      end

      it "should return items as YAML" do
        expect(subject.output_feedback).to eq_as_yaml(["ITEM 1", "ITEM 2"])
      end
    end
  end

  describe "#round_float" do
    it "should round a float to a certain precision" do
      expect(subject.round_float(1)).to eq(1.000)
      expect(subject.round_float(123.4567)).to eq(123.457)
      expect(subject.round_float(123.456781, 5)).to eq(123.45678)
    end
  end

  describe "#format_float" do
    it "should format a float to a certain precision" do
      expect(subject.format_float(1)).to eq("1")
      expect(subject.format_float(123.45, 5)).to eq("123.45")
      expect(subject.format_float(123.4567)).to eq("123.457")
      expect(subject.format_float(123.456781, 5)).to eq("123.45678")
    end
  end

  describe "#execute_command" do
    it "should return the output of a command" do
      expect(subject.send(:execute_command, "date", "+%s")).to match(/\d+/)
    end
  end
end