# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

require "spec_helper"

describe Pincerna::Cache do
  before(:each) do
    Pincerna::Cache.instance_variable_set(:@instance, nil)
    stub_const("Pincerna::Cache::FILE", "/tmp/pincerna-cache.db")
    allow_any_instance_of(EventMachine::PeriodicTimer).to receive(:schedule)
  end

  after(:each) do
    Pincerna::Cache.instance.destroy
    FileUtils.rm_f(Pincerna::Cache::FILE)
  end

  describe ".instance" do
    it "should return the instance" do
      expect(Pincerna::Cache).to receive(:new).once.and_call_original
      instance = Pincerna::Cache.instance
      expect(instance).to be_a(Pincerna::Cache)
      expect(instance).to be(Pincerna::Cache.instance)
    end
  end

  describe "#initialize" do
    it "should initialize variables" do
      expect(Pincerna::Cache.instance.instance_variable_get(:@flusher)).to be_a(EventMachine::PeriodicTimer)
      expect(Pincerna::Cache.instance.instance_variable_get(:@data)).to be_a(Daybreak::DB)
    end
  end

  describe "#use" do
    before(:each) do
      allow(Time).to receive(:now).and_return(1000)
      @control = ""
    end

    it "should read data from the store and not call the block, if present" do
      Pincerna::Cache.instance.data["KEY"] = {expiration: Time.now.to_f + 1800, data: "1"}
      expect(Pincerna::Cache.instance.use("KEY", 1800) { @control = "2" }).to eq("1")
      expect(@control).to eq("")
    end

    it "should fetch new data if nothing is in cache, then save it back" do
      Pincerna::Cache.instance.data["KEY"] = nil
      expect(Pincerna::Cache.instance.use("KEY", 1800) { @control = "2" }).to eq("2")
      expect(Pincerna::Cache.instance.data["KEY"]).to eq({data: "2", expiration: 2800})
      expect(@control).to eq("2")
    end

    it "should fetch new data if the old one expired" do
      Pincerna::Cache.instance.data["KEY"] = {expiration: 800, data: "1"}
      expect(Pincerna::Cache.instance.use("KEY", 1800) { @control = "2" }).to eq("2")
      expect(Pincerna::Cache.instance.data["KEY"]).to eq({data: "2", expiration: 2800})
      expect(@control).to eq("2")
    end
  end

  describe "#destroy" do
    before(:each) do
      flusher = Pincerna::Cache.instance.instance_variable_get(:@flusher)
      data = Pincerna::Cache.instance.instance_variable_get(:@data)
      expect(flusher).to receive(:cancel).twice
      expect(data).to receive(:close).twice.and_call_original
    end

    it "should cancel the flusher and close the data" do
      Pincerna::Cache.instance.destroy
    end
  end

  describe "#flush" do
    before(:each) do
      data = Pincerna::Cache.instance.instance_variable_get(:@data)
      expect(data).to receive(:flush)
      expect(data).to receive(:compact)
    end

    it "should flush and compact data" do
      Pincerna::Cache.instance.flush
    end
  end
end