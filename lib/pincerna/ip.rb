# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Pincerna
  # Shows the IP addresses of all network interfaces.
  class Ip < Base
    # The expression to match.
    MATCHER = /^(?<all>.*)$/i

    # The icon to show for each feedback item.
    ICON = Pincerna::Base::ROOT + "/images/network.png"

    # Shows the IP addresses of all network interfaces.
    #
    # @param query [Array] A query to match against interfaces names.
    # @return [Array] A list of items to process.
    def perform_filtering(query)    
      @interface_filter ||= query.empty? ? /.*/ : /#{query}/i

      # Get local addresses
      rv = get_local_addresses

      # Sort interfaces and address, IPv4 first then IPv6
      rv.sort! {|left, right|
        cmp = left[:interface] <=> right[:interface] # Interface name first
        cmp = compare_ip_classes(left[:address], right[:address]) if cmp == 0 # Now IPv4 first then IPv6
        cmp = compare_ip_addresses(left[:address], right[:address]) if cmp == 0 # Finally addresses
        cmp
      }

      # Add public address
      rv = rv.insert(0, get_public_address) if @interface_filter.match("public")

      rv
    end

    # Processes items to obtain feedback items.
    #
    # @param results [Array] The items to process.
    # @return [Array] The feedback items.
    def process_results(results)
      results.collect do |result|
        title = "#{result[:interface] ? result[:interface] : "Public"} IP: #{result[:address]}"
        {title: title, arg: result[:address], subtitle: "Action this item to copy the IP on the clipboard.", icon: self.class::ICON}
      end
    end

    # Gets a list of local IP addresses.
    #
    # @return [Array] A list of IPs data.
    def get_local_addresses
      rv = []
      names = get_interfaces_names

      # Split by interfaces
      interfaces = execute_command("/sbin/ifconfig").split(/(^\S+:\s+)/)
      interfaces.shift # Discard first whitespace

      # For each interface
      interfaces.each_slice(2) do |interface, configuration|
        # See if matches the query and then replace public name
        interface = interface.gsub(/\s*(.+):\s*/, "\\1")
        name = names[interface] ? "#{names[interface]} (#{interface})" : interface
        next if !@interface_filter.match(name)

        # Get addresses
        addresses = StringScanner.new(configuration)
        while addresses.scan_until(/inet(6?)\s/) do
          rv << {interface: name, address: addresses.scan(/\S+/)}
        end
      end

      rv
    end

    # Gets the public IP address for this machine.
    #
    # @return [Hash] The public IP address data.
    def get_public_address
      {interface: nil, address: fetch_remote_resource("http://api.externalip.net/ip", {}, false)}
    end

    # Compares two IP classes, giving higher priority to IPv4.
    #
    # @param left [String] The first IP to compare.
    # @param right [String] The second IP to compare.
    # @return [Fixnum] The result of the comparison.
    def compare_ip_classes(left, right)
      (left.index(":") ? 1 : 0) <=> (right.index(":") ? 1 : 0)
    end

    # Compares to IP addresses, giving higher priority to local address such as 127.0.0.1.
    #
    # @param left [String] The first IP to compare.
    # @param right [String] The second IP to compare.
    # @return [Fixnum] The result of the comparison.
    def compare_ip_addresses(left, right)
      higher_priority = ["::1", "127.0.0.1", "10.0.0.1"]
      cmp = (higher_priority.include?(left) ? 0 : 1) <=> (higher_priority.include?(right) ? 0 : 1)
      cmp = left <=> right if cmp == 0
      cmp
    end

    # Gets a hash with pair of interfaces and their human names.
    #
    # @return [Hash] The hash with interfaces' name.
    def get_interfaces_names
      rv = {"lo0" => "Loopback"}

      names = execute_command("/usr/sbin/networksetup", "-listallhardwareports").split(/\n\n/)
      names.shift # Discard first whitespace
      
      names.each do |port|
        port = StringScanner.new(port)
        name = nil
        interface = nil
        
        if port.scan_until(/Hardware Port: /) then
          name = port.scan_until(/\n/).strip
          interface = port.scan_until(/\n/).strip if port.scan_until(/Device: /)
        end

        rv[interface] = name if name && interface
      end

      rv
    end
  end
end
