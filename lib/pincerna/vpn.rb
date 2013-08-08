# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Pincerna
  # Connects or disconnects from system's VPNs.
  class Vpn < Base
    # The expression to match.
    MATCHER = /^(?<all>.*)$/i

    # The icon to show for each feedback item.
    ICON = Pincerna::Base::ROOT + "/images/network.png"

    # Connects to or disconnects from system VPN.
    #
    # @param query [Array] A query to match against VPNs names.
    # @return [Array] A list of items to process.
    def perform_filtering(query)
      rv = []
      interface_filter ||= query.empty? ? /.+/ : /#{query}/i

      execute_command("/usr/sbin/networksetup", "-listnetworkserviceorder").split(/\n\n/).each do |i|
        # Scan every interface
        token = StringScanner.new(i)

        if token.scan_until(/^\(\d+\)/) then
          name = token.scan_until(/\n/).strip # Get VPN name
          next if !interface_filter.match(name)

          # Get the type
          token.scan_until(/Hardware Port:\s/)

          # If type matches
          rv << {name: name, connected: vpn_connected?(name)} if is_vpn_service?(token.scan_until(/,/))
        end
      end

      rv
    end

    # Processes items to obtain feedback items.
    #
    # @param results [Array] The items to process.
    # @return [Array] The feedback items.
    def process_results(results)
      results.collect do |result|
        title = "#{result[:connected] ? "Disconnect from" : "Connect to"} #{result[:name]}"
        subtitle = "Action this item to #{result[:connected] ? "disconnect from" : "connect to"} the VPN service."
        arg = "#{result[:connected] ? "disconnect" : "connect"} service \"#{result[:name]}\""

        {title: title, arg: arg, subtitle: subtitle, icon: self.class::ICON}
      end
    end

    # Checks if a VPN is connected.
    #
    # @param name [String] The VPN's name.
    # @return [Boolean] `true` if the VPN is connected, `false` otherwise.
    def vpn_connected?(name)
      execute_command("/usr/sbin/networksetup", "-showpppoestatus", "\"#{name}\"").strip == "connected"
    end

    private
      # Check if a service is a VPN.
      #
      # @param service [String] The service name.
      # @return `true` if the service is a VPN service, `false` otherwise.
      def is_vpn_service?(service)
        ["L2TP", "IPSec"].include?(service.gsub(/,$/, ""))
      end
  end
end
