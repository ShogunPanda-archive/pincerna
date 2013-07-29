# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Pincerna::CurrencyConversion do
  subject { Pincerna::CurrencyConversion.new("QUERY") }

  describe "matching" do
    it "should match valid queries" do
      allow_any_instance_of(Pincerna::CurrencyConversion).to receive(:perform_filtering) { |*args| args }
      allow_any_instance_of(Pincerna::CurrencyConversion).to receive(:process_results) { |*args| args }

      expect(Pincerna::CurrencyConversion.new("123 EUR to GBP").filter).to eq_as_yaml([[123.0, "EUR", "GBP", false]])
      expect(Pincerna::CurrencyConversion.new("-123.45 eur usd").filter).to eq_as_yaml([[-123.45, "EUR", "USD", false]])
      expect(Pincerna::CurrencyConversion.new("123 EUR to GBP with rate").filter).to eq_as_yaml([[123.0, "EUR", "GBP", true]])
    end

    it "should not match invalid queries" do
      expect_any_instance_of(Pincerna::CurrencyConversion).not_to receive(:perform_filtering)
      expect_any_instance_of(Pincerna::CurrencyConversion).not_to receive(:process_results)

      expect(Pincerna::CurrencyConversion.new("12A3 EUR to GBP").filter).to eq_as_yaml([])
    end
  end

  describe "#perform_filtering", :vcr do
    it "should return valid values" do
      expect(subject.perform_filtering(123.45, "EUR", "USD", "RATE")).to eq({value: 123.45, from: "EUR", to: "USD", result: 163.892, rate: 1.328, with_rate: "RATE"})
    end
  end

  describe "#process_results" do
    before(:each) do
      @value = {value: 123.45, from: "EUR", to: "USD", result: 163.892, rate: 1.328, with_rate: nil}
    end

    it "should correctly prepare results" do
      expect(subject.process_results(@value)).to eq([{title: "123.45 EUR = 163.892 USD", arg: "123.45", subtitle: "Action this item to copy the converted amount on the clipboard.", icon: Pincerna::CurrencyConversion::ICON}])
      expect(subject.process_results(@value.merge(with_rate: true))).to eq([{title: "123.45 EUR = 163.892 USD (1 EUR = 1.328 USD)", arg: "123.45", subtitle: "Action this item to copy the converted amount on the clipboard.", icon: Pincerna::CurrencyConversion::ICON}])
    end
  end
end