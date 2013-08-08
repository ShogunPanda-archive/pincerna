# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Pincerna::UnitConversion do
  subject { Pincerna::UnitConversion.new("QUERY", "yml") }

  describe "matching" do
    it "should match valid queries" do
      allow_any_instance_of(Pincerna::UnitConversion).to receive(:perform_filtering) { |*args| args }
      allow_any_instance_of(Pincerna::UnitConversion).to receive(:process_results) { |*args| args }

      expect(Pincerna::UnitConversion.new("123 m to F", "yml").filter).to eq_as_yaml([[123.0, "m", "F", false, false]])
      expect(Pincerna::UnitConversion.new("-123.45 oz kg split units", "yml").filter).to eq_as_yaml([[-123.45, "oz", "kg", false, true]])
      expect(Pincerna::UnitConversion.new("123 m to yd with rate", "yml").filter).to eq_as_yaml([[123.0, "m", "yd", true, false]])
    end

    it "should not match invalid queries" do
      expect_any_instance_of(Pincerna::UnitConversion).not_to receive(:perform_filtering)
      expect_any_instance_of(Pincerna::UnitConversion).not_to receive(:process_results)

      expect(Pincerna::UnitConversion.new("12A3 EUR to GBP", "yml").filter).to eq_as_yaml([])
    end
  end

  describe "#perform_filtering" do
    it "should return valid values" do
      converted = subject.perform_filtering(123, "mi", "km", "RATE", "SPLIT")
      expect(converted.delete(:value)).to eq_as_unit(Unit.new("123 mi"))
      expect(converted.delete(:unit)).to eq_as_unit(Unit.new("1 mi"))
      expect(converted.delete(:result)).to eq_as_unit(Unit.new("197.949312 km"))
      expect(converted.delete(:rate)).to eq_as_unit(Unit.new("1.609344 km"))
      expect(converted).to eq({from: "mi", to: "km", with_rate: "RATE", multiple: "SPLIT"})
    end
  end

  describe "#process_results" do
    before(:each) do
      @value = {value: Unit.new("123 kg"), from: "kg", to: "oz", unit: Unit.new("1 kg"), result: Unit.new("4338.69 oz"), rate: Unit.new("35.278 oz"), with_rate: nil, multiple: nil}
    end

    it "should correctly prepare results" do
      expect(subject.process_results(@value)).to eq([{title: "123 kg = 4338.690 oz", arg: 4338.69, subtitle: "Action this item to copy the converted amount on the clipboard.", icon: Pincerna::UnitConversion::ICON}])
      expect(subject.process_results(@value.merge(with_rate: true))).to eq([{title: "123 kg = 4338.690 oz (1 kg = 35.278 oz)", arg: 4338.69, subtitle: "Action this item to copy the converted amount on the clipboard.", icon: Pincerna::UnitConversion::ICON}])
      expect(subject.process_results(@value.merge(multiple: true))).to eq([{title: "123 kg = 271 lbs 2 oz", arg: 4338.69, subtitle: "Action this item to copy the converted amount on the clipboard.", icon: Pincerna::UnitConversion::ICON}])
      expect(subject.process_results(@value.merge(with_rate: true, multiple: true))).to eq([{title: "123 kg = 271 lbs 2 oz (1 kg = 2 lbs 3 oz)", arg: 4338.69, subtitle: "Action this item to copy the converted amount on the clipboard.", icon: Pincerna::UnitConversion::ICON}])
    end
  end

  describe "#check_temperature" do
    it "should correctly convert a temperature unit" do
      expect(subject.check_temperature("C")).to eq("tempC")
      expect(subject.check_temperature("c")).to eq("tempC")
      expect(subject.check_temperature("F")).to eq("tempF")
      expect(subject.check_temperature("°K")).to eq("tempK")
      expect(subject.check_temperature("m")).to eq("m")
    end
  end

  describe "#convert_value" do
    it "should correctly convert units" do
      expect(subject.convert_value(1, "mi", "km")).to eq_as_unit(Unit.new("1.609344 mi"))
      expect(subject.convert_value(1, "gal", "L")).to eq_as_unit(Unit.new("3.785411784 L"))
    end
  end

  describe "#format_value" do
    it "should correctly format values" do
      expect(subject.format_value(Unit.new("123.456789 oz"))).to eq("123.457 oz")
      expect(subject.format_value(Unit.new("123.456789 oz"), nil, 1)).to eq("123.5 oz")
      expect(subject.format_value(Unit.new("123.456789 oz"), :raw)).to eq(123.457)
      expect(subject.format_value(Unit.new("123.456789 oz"), :raw, 6)).to eq(123.456789)
      expect(subject.format_value(Unit.new("123.456789 oz"), true)).to eq("7 lbs 11 oz")
      expect(subject.format_value(Unit.new("123.456789 oz"), true, 6)).to eq("7 lbs 11 oz")
      expect(subject.format_value(Unit.new("123.00000 oz"))).to eq("123 oz")
      expect(subject.format_value(Unit.new("123.000123 oz"))).to eq("123 oz")
    end
  end
end