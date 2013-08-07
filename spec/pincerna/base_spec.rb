# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"
require "yaml"
require "pincerna/map"

describe Pincerna::Base do
  subject { Pincerna::Base.new("QUERY") }

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
      expect(Pincerna::Map).to receive(:new).with("QUERY").and_return(query)
      expect(Pincerna::Base.execute!("map", "QUERY"))
    end

    it "should not fail if a matching class is not found" do
      expect { expect(Pincerna::Base.execute!("invalid", "QUERY")) }.not_to raise_error
    end
  end

  describe "#initalize" do
    it "should initialize correct attributes" do
      expect(subject.instance_variable_get(:@query)).to eq("QUERY")
      expect(subject.instance_variable_get(:@cache_dir)).to eq(::File.expand_path("~/Library/Caches/com.runningwithcrayons.Alfred-2/Workflow Data/pincerna"))
      expect(subject.instance_variable_get(:@feedback_items)).to eq([])
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

  describe "#setup_vcr" do
    after(:each) do
      configure_vcr
    end

    it "should load ::VCR and ::WebMock and set some constants" do
      config = ::VCR::Configuration.new
      expect(config).to receive(:hook_into).with(:webmock).at_least(1)
      expect(::VCR).to receive(:configure).at_least(1).and_yield(config)

      subject.send(:setup_vcr)
      expect(::VCR).to be_a(::Module)
      expect(::WebMock).to be_a(::Module)
      expect(config.allow_http_connections_when_no_cassette?).to be_true
      expect(config.cassette_library_dir).to eq(::File.expand_path("~/Library/Caches/com.runningwithcrayons.Alfred-2/Workflow Data/pincerna") + "/http")
      expect(config.default_cassette_options[:record]).to eq(:once)
    end
  end

  describe "#log" do
    before(:each) do
      @log_path = "/tmp/pincerna.log"
      allow(subject).to receive(:debug_mode).and_return(true)
      allow(subject).to receive(:log_path).and_return(@log_path)
      expect_any_instance_of(Time).to receive(:strftime).and_return("TIME")
      allow(::File).to receive(:absolute_path).and_return(@log_path)
    end

    it "should log a message" do
      ::File.delete(@log_path) if ::File.exists?(@log_path)
      subject.send(:log, "MESSAGE")
      expect(::File.read(@log_path)).to eq("[TIME] MESSAGE\n")
      ::File.delete(@log_path)
    end
  end
end