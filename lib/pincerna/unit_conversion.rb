# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Pincerna
  # Converts a value from a unit to another.
  class UnitConversion < Base
    # The expression to match.
    MATCHER = /^
      (([+-]?)(\d+)([.,]\d+)?) # Currency
      \s+
      ([a-z°]+?) # From value
      \s+
      (to\s+)?
      ([a-z°]+) # To value
      (\s+with\s+rate)? # Optional
      (\s+split\s+units)? # Option
    $/mix

    # Relevant groups in the match.
    RELEVANT_MATCHES = {
      1 => Proc.new {|context, value| context.round_float(value.gsub(",", ".").to_f) }, # Value
      5 => Proc.new {|_, value| value }, # Origin unit
      7 => Proc.new {|_, value| value }, # Target unit
      8 => Proc.new {|_, value| !value.nil? }, # If to show rate
      9 => Proc.new {|_, value| !value.nil? } # If group unit for ft+in and lb+oz
    }

    # The icon to show for each feedback item.
    ICON = Pincerna::Base::ROOT + "/images/unit.png"

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

      original = convert_value(value, from, from)
      base = convert_value(1, from, from)
      converted = convert_value(value, from, to)
      rate = convert_value(1, from, to)

      converted ? {:from => from, :to => to, :value => original, :unit => base, :result => converted, :rate => rate, :with_rate => with_rate, :multiple => multiple} : nil
    end

    # Processes items to obtain feedback items.
    #
    # @param results [Hash] The items to process.
    # @return [Array] The feedback items.
    def process_results(results)
      multiple = results[:multiple]
      title = "#{format_value(results[:value], multiple)} = #{format_value(results[:result], multiple)}"
      title << " (#{format_value(results[:unit], multiple)} = #{format_value(results[:rate], multiple)})" if results[:with_rate]

      [{:title => title, :arg => format_value(results[:result], :raw), :subtitle => "Action this item to copy the converted amount on the clipboard.", :icon => self.class::ICON}]
    end

    # Checks if a unit is a temperature and adds "deg" if needed.
    #
    # @param unit [String] The unit to check.
    # @return [String] The adjusted unit.
    def check_temperature(unit)
      unit = unit.gsub("°", "")
      /^[CFKR]$/.match(unit.upcase) ? "deg#{unit}" : unit
    end

    # Converts a value from a unit to another.
    #
    # @param value [Float] The value to convert.
    # @param from [String] The origin unit.
    # @param to [String] The target unit.
    # @return [String|NilClass] The converted unit or `nil` if the conversion failed.
    def convert_value(value, from, to)
      begin
        Unit.new("#{value} #{from}").convert_to(to)
      rescue
        nil
      end
    end

    # Formats a value.
    #
    # @param value [String] The value to format.
    # @param multiple [Boolean] If to use multiple units for ft (ft+in) and lb/oz (lb+oz).
    # @return [String] The formatted value.
    def format_value(value, multiple)
      if multiple != :raw then
        format = "%0.3f"
        units = value.units

        if multiple && units =~ /ft|oz|lb/ then
          format = units == "ft" ? :ft : :lbs
        elsif value.round == value then
          format = "%0.0f"
        end

        value.to_s(format).gsub(", ", " ").gsub(/ deg([CFKR])/, "°\\1")
      else
        round_float(value.scalar)
      end
    end
  end
end
