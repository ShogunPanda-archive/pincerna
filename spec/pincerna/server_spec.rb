# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

require "goliath/test_helper"
require "spec_helper"
require "pincerna/server"

describe Pincerna::Server do
  include Goliath::TestHelper

  subject{ ::Pincerna::Server.new }

  before(:each) do
    allow(subject).to receive(:params).and_return({})
    allow(EM::Synchrony).to receive(:sleep)
  end

  describe ".enqueue_request" do
    before(:each) do
      allow(Time).to receive(:now).and_return(1)
      expect(EM::Synchrony).to receive(:sleep).with(Pincerna::Server::DELAY)
    end

    it "should enqueue a request" do
      Pincerna::Server.enqueue_request
      expect(Pincerna::Server.instance_variable_get(:@requests).pop).to eq(1)
    end
  end

  describe ".perform_request?" do
    it "should check if the request must be performed" do
      queue = Queue.new
      Pincerna::Server.instance_variable_set(:@requests, queue)
      queue << 1
      expect(Pincerna::Server.perform_request?).to be_true
      queue << 2
      queue << 3
      expect(Pincerna::Server.perform_request?).to be_false
    end
  end

  describe "#handle_request" do
    before(:each) do
      @queue = Queue.new
      Pincerna::Server.instance_variable_set(:@requests, @queue)
    end

    it "should handle valid requests" do
      expect(Pincerna::Base).to receive(:execute!).with("map", "Campobasso", "YML", "NO").and_call_original
      allow_any_instance_of(Pincerna::Base).to receive(:output).and_return("RESPONSE")
      expect(subject.handle_request("map", {"q" => "Campobasso  ", "format" => "YML", "debug" => "NO"})).to eq([200, {"Content-Type" => "text/x-yaml"}, "RESPONSE"])
    end

    it "should handle invalid requests" do
      expect(subject.handle_request("mappa", {"q" => "Campobasso  ", "format" => "YML", "debug" => "NO"})).to eq([404, {"Content-Type" => "text/plain"}, ""])
    end

    it "should handle outdated requests" do
      @queue << 1

      expect(Pincerna::Base).not_to receive(:execute!)
      expect(subject.handle_request("mappa", {"q" => "Campobasso  ", "format" => "YML", "debug" => "NO"})).to eq([429, {"Content-Type" => "text/plain"}, ""])
    end
  end

  describe "#handle_stop" do
    it "should setup a callback and return 200" do
      expect(EM).to receive(:add_timer).with(0.1)
      expect(subject.handle_stop).to eq([200, {}, ""])
    end
  end

  describe "#stop_server" do
    it "should destroy the cache and stop EM in the callback" do
      allow_any_instance_of(EventMachine::PeriodicTimer).to receive(:schedule)
      expect(Pincerna::Cache.instance).to receive(:destroy).and_call_original
      expect(EM).to receive(:stop)
      subject.send(:stop_server)
    end
  end

  describe "#response" do
    before(:each) do
      allow(subject).to receive(:handle_request).and_return([1, {}, ""])
      allow(subject).to receive(:handle_stop).and_return([2, {}, ""])
      allow(subject).to receive(:handle_install).and_return([3, {}, ""])
      allow(subject).to receive(:handle_uninstall).and_return([4, {}, ""])
    end

    it "should return the response" do
      expect(subject.response({"REQUEST_PATH" => "/"})).to eq([1, {}, ""])
      expect(subject.response({"REQUEST_PATH" => "foo/quit"})).to eq([1, {}, ""])
      expect(subject.response({"REQUEST_PATH" => "/quit"})).to eq([2, {}, ""])
      expect(subject.response({"REQUEST_PATH" => "/install"})).to eq([3, {}, ""])
      expect(subject.response({"REQUEST_PATH" => "/uninstall"})).to eq([4, {}, ""])
    end

    it "should handle exceptions" do
      allow(subject).to receive(:handle_request).and_raise(RuntimeError.new("NO"))
      response = subject.response({"REQUEST_PATH" => "/"})
      expect(response[0]).to eq(500)
      expect(response[1]).to eq({"X-Error" => "RuntimeError", "X-Error-Message" => "NO", "Content-Type" => "text/plain"})
    end
  end
end