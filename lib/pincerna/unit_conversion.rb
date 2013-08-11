# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Pincerna
  # Converts a value from a unit to another.
  class UnitConversion < Base
    # The expression to match.
    MATCHER = /^
      (?<value>([+-]?)(\d+)([.,]\d+)?)
      \s+
      (?<from>\S+?)
      \s+
      (to\s+)?
      (?<to>\S+)
      (?<rate>\s+with\s+rate)?
      (?<split>\s+split\s+units)?
    $/mix

    # Relevant groups in the match.
    RELEVANT_MATCHES = {
      "value" => ->(context, value) { context.round_float(value.gsub(",", ".").to_f) },
      "from" => ->(_, value) { value },
      "to" => ->(_, value) { value },
      "rate" => ->(_, value) { !value.nil? }, # If show conversion rate
      "split" => ->(_, value) { !value.nil? } # If group unit for ft+in and lb+oz
    }

    # The icon to show for each feedback item.
    ICON = Pincerna::Base::ROOT + "/images/unit.png"

    # Defines a new unit.
    #
    # @param name [String] The name of the unit.
    # @param definition [String] The definition of the unit.
    # @param aliases [Array] The aliases of this unit.
    def self.define_unit(name, definition, aliases)
      RubyUnits::Unit.define(name) do |unit|
        unit.definition = RubyUnits::Unit.new(definition)
        unit.aliases = aliases
      end
    end

    # Converts a value from a unit to another.
    #
    # @param value [Float] The value to convert.
    # @param from [String] The origin unit.
    # @param to [String] The target unit.
    # @param with_rate [Boolean] If to return the conversion rate in the results.
    # @param multiple [Boolean] If to use multiple units for ft (ft+in) and lb/oz (lb+oz).
    # @return [Hash|NilClass] The converted data or `nil` if the conversion failed.
    def perform_filtering(value, from, to, with_rate, multiple)
      from = check_temperature(from)
      to = check_temperature(to)
      converted = convert_value(value, from, to)
      converted ? {from: from, to: to, value: convert_value(value, from, from), unit: convert_value(1, from, from), result: converted, rate: convert_value(1, from, to), with_rate: with_rate, multiple: multiple} : nil
    end

    # Processes items to obtain feedback items.
    #
    # @param results [Hash] The items to process.
    # @return [Array] The feedback items.
    def process_results(results)
      multiple = results[:multiple]
      title = "#{format_value(results[:value], multiple)} = #{format_value(results[:result], multiple)}"
      title << " (#{format_value(results[:unit], multiple)} = #{format_value(results[:rate], multiple)})" if results[:with_rate]

      [{title: title, arg: format_value(results[:result], :raw), subtitle: "Action this item to copy the converted amount on the clipboard.", icon: self.class::ICON}]
    end

    # Checks if a unit is a temperature and prepend "temp" if needed.
    #
    # @param unit [String] The unit to check.
    # @return [String] The adjusted unit.
    def check_temperature(unit)
      unit = unit.gsub("°", "")
      /^[CFKR]$/.match(unit.upcase) ? "temp#{unit.upcase}" : unit
    end

    # Converts a value from a unit to another.
    #
    # @param value [Float] The value to convert.
    # @param from [String] The origin unit.
    # @param to [String] The target unit.
    # @return [String|NilClass] The converted unit or `nil` if the conversion failed.
    def convert_value(value, from, to)
      Unit.new("#{value} #{from}").convert_to(to)
    end

    # Formats a value.
    #
    # @param value [String] The value to format.
    # @param modifier [Boolean|Symbol] If to use multiple units for ft (ft+in) and lb/oz (lb+oz). If `:raw`, only the unitless (float) value is returned.
    # @param precision [Fixnum] The precision to use for rounding.
    # @return [String|Float] The formatted value or the unitless value.
    def format_value(value, modifier = nil, precision = 3)
      rounded = round_float(value.scalar.to_f, precision)

      if modifier != :raw then
        format = "%0.#{precision}f"
        units = value.units

        if modifier && units =~ /ft|oz|lb/ then
          format = units == "ft" ? :ft : :lbs
        elsif rounded.to_i == rounded then
          format = "%0.0f"
        end

        value.to_s(format).gsub(", ", " ").gsub(/ temp([CFKR])/, "°\\1")
      else
        rounded
      end
    end
  end
end

Pincerna::UnitConversion.define_unit("miles per gallon", "1 mi/gal", ["mpg" "miles-per-gallon"])
Pincerna::UnitConversion.define_unit("kilometers per liter", "1 km/L", ["kpl" "kilometers-per-liter"])