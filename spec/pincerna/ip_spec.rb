# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Pincerna::Ip do
  subject { Pincerna::Ip.new("") }

  before(:each) do
    @ifconfig = <<EOIP
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
	options=3<RXCSUM,TXCSUM>
	inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
	inet 127.0.0.1 netmask 0xff000000
	inet6 ::1 prefixlen 128
gif0: flags=8010<POINTOPOINT,MULTICAST> mtu 1280
stf0: flags=0<> mtu 1280
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=2b<RXCSUM,TXCSUM,VLAN_HWTAGGING,TSO4>
	ether 11:22:33:44:55:66
	media: autoselect (none)
	status: inactive
en1: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 11:22:33:44:55:66
	inet6 fe80::6aa8:6dff:fe2e:5afc%en1 prefixlen 64 scopeid 0x5
	inet 192.168.1.21 netmask 0xffffff00 broadcast 192.168.1.255
	media: autoselect
	status: active
fw0: flags=8822<BROADCAST,SMART,SIMPLEX,MULTICAST> mtu 4078
	lladdr 11:22:33:44:55:66:77:88
	media: autoselect <full-duplex>
	status: inactive
p2p0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 2304
	ether 11:22:33:44:55:66
	media: autoselect
	status: inactive
utun0: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1380
	inet6 fe80::b5bc:eb1b:ee64:cd82%utun0 prefixlen 64 scopeid 0x8
	inet6 fd3e:ebdd:9d87:a608:b5bc:eb1b:ee64:cd82 prefixlen 64
EOIP

  @networksetup = <<EONAMES

Hardware Port: Bluetooth DUN
Device: Bluetooth-Modem
Ethernet Address: N/A

Hardware Port: Ethernet
Device: en0
Ethernet Address: 11:22:33:44:55:66

Hardware Port: FireWire
Device: fw0
Ethernet Address: 11:22:33:44:55:66:77:88

Hardware Port: Wi-Fi
Device: en1
Ethernet Address: 11:22:33:44:55:66

Hardware Port: Bluetooth PAN
Device: en2
Ethernet Address: N/A

VLAN Configurations
===================
EONAMES

    allow_any_instance_of(Pincerna::Ip).to receive(:execute_command) { |*args| args[0] == "/sbin/ifconfig" ? @ifconfig : @networksetup }
  end

  describe "matching" do
    it "should allow both empty and present queries" do
      allow_any_instance_of(Pincerna::Ip).to receive(:perform_filtering) { |args| [args] }
      allow_any_instance_of(Pincerna::Ip).to receive(:process_results) { |args| args }

      expect(Pincerna::Ip.new("QUERY").filter).to eq_as_yaml(["QUERY"])
      expect(Pincerna::Ip.new("").filter).to eq_as_yaml([""])
    end
  end

  describe "#perform_filtering" do
    before(:each) do
      allow(subject).to receive(:get_public_address).and_return({interface: nil, address: "76.126.167.79"})
    end

    describe "should return list of IPs" do
      it "with no query" do
        expect(subject.perform_filtering("")).to eq([
          {interface: nil, address: "76.126.167.79"},
          {interface: "Loopback (lo0)", address: "127.0.0.1"},
          {interface: "Loopback (lo0)", address: "::1"},
          {interface: "Loopback (lo0)", address: "fe80::1%lo0"},
          {interface: "Wi-Fi (en1)", address: "192.168.1.21"},
          {interface: "Wi-Fi (en1)", address: "fe80::6aa8:6dff:fe2e:5afc%en1"},
          {interface: "utun0", address: "fd3e:ebdd:9d87:a608:b5bc:eb1b:ee64:cd82"},
          {interface: "utun0", address: "fe80::b5bc:eb1b:ee64:cd82%utun0"}
        ])
      end

      it "with query" do
        expect(subject.perform_filtering("p")).to eq([
          {interface: nil, address: "76.126.167.79"},
          {interface: "Loopback (lo0)", address: "127.0.0.1"},
          {interface: "Loopback (lo0)", address: "::1"},
          {interface: "Loopback (lo0)", address: "fe80::1%lo0"}
        ])

        subject.instance_variable_set(:@interface_filter, nil)
        expect(subject.perform_filtering("wi")).to eq([
          {interface: "Wi-Fi (en1)", address: "192.168.1.21"},
          {interface: "Wi-Fi (en1)", address: "fe80::6aa8:6dff:fe2e:5afc%en1"}
        ])
      end
    end
  end

  describe "#process_results" do
    before(:each) do
      @value = [{interface: "INTERFACE", address: "IP 1"}, {interface: nil, address: "IP 2"}]
    end

    it "should correctly prepare results" do
      expect(subject.process_results(@value)).to eq([
        {title: "INTERFACE IP: IP 1", arg: "IP 1", subtitle: "Action this item to copy the IP on the clipboard.", icon: Pincerna::Ip::ICON},
        {title: "Public IP: IP 2", arg: "IP 2", subtitle: "Action this item to copy the IP on the clipboard.", icon: Pincerna::Ip::ICON}
      ])
    end
  end

  describe "#get_local_addresses", :vcr do
    before(:each) do
      subject.instance_variable_set(:@interface_filter, /.*/i)
      expect(subject).to receive(:get_interfaces_names).and_return({"en0" => "Ethernet", "fw0" => "FireWire", "en1" => "Wi-Fi", "en2" => "Bluetooth PAN", "lo0" => "Loopback"})
      expect(subject).to receive(:execute_command).with("/sbin/ifconfig").and_return(@ifconfig)
    end

    it "should return a list of addresses" do
      expect(subject.get_local_addresses).to eq([
        {interface: "Loopback (lo0)", address: "fe80::1%lo0"},
        {interface: "Loopback (lo0)", address: "127.0.0.1"},
        {interface: "Loopback (lo0)", address: "::1"},
        {interface: "Wi-Fi (en1)", address: "fe80::6aa8:6dff:fe2e:5afc%en1"},
        {interface: "Wi-Fi (en1)", address: "192.168.1.21"},
        {interface: "utun0", address: "fe80::b5bc:eb1b:ee64:cd82%utun0"},
        {interface: "utun0", address: "fd3e:ebdd:9d87:a608:b5bc:eb1b:ee64:cd82"}
      ])
    end
  end

  describe "#get_public_address", :vcr do
    it "should return public IP address" do
      address = subject.get_public_address

      expect(address.keys).to eq([:interface, :address])
      expect(address[:interface]).to be_nil
      expect(address[:address]).to eq("8.8.8.8")
    end
  end

  describe "#compare_ip_classes" do
    it "should compare IP classes" do
      expect(subject.compare_ip_classes("127.0.0.1", "::1")).to eq(-1)
      expect(subject.compare_ip_classes("::1", "::fe80:aabb")).to eq(0)
      expect(subject.compare_ip_classes("::1", "127.0.0.1")).to eq(1)
    end
  end

  describe "#compare_ip_addresses" do
    it "should correctly compare IP addresses" do
      expect(subject.compare_ip_addresses("127.0.0.1", "::1")).to eq(-1)
      expect(subject.compare_ip_addresses("::1", "127.0.0.1")).to eq(1)
      expect(subject.compare_ip_addresses("127.0.0.1", "192.168.0.1")).to eq(-1)
      expect(subject.compare_ip_addresses("192.168.0.0", "192.168.0.1")).to eq(-1)
      expect(subject.compare_ip_addresses("192.168.0.1", "192.168.0.1")).to eq(0)
      expect(subject.compare_ip_addresses("127.0.0.1", "10.0.0.1")).to eq(1)
      expect(subject.compare_ip_addresses("::1", "::fe80:aabb")).to eq(-1)
      expect(subject.compare_ip_addresses("::fe80:aabe", "::fe80:aabd")).to eq(1)
      expect(subject.compare_ip_addresses("::fe80:aaaa", "::fe80:aaaa")).to eq(0)
    end
  end

  describe "#get_interfaces_names" do
    before(:each) do
      expect(subject).to receive(:execute_command).with("/usr/sbin/networksetup", "-listallhardwareports").and_return(@networksetup)
    end

    it "should return the current names of system interfaces" do
      expect(subject.get_interfaces_names).to eq({"en0" => "Ethernet", "fw0" => "FireWire", "en1" => "Wi-Fi", "en2" => "Bluetooth PAN", "lo0" => "Loopback"})
    end
  end
end
