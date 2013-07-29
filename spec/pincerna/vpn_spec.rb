# encoding: utf-8
#
# This file is part of the pincerna gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Pincerna::Vpn do
  subject { Pincerna::Vpn.new("QUERY") }

  describe "#perform_filtering" do
    before(:each) do
      allow(subject).to receive(:vpn_connected?) {|name| name == "VPN 2" }

      allow(subject).to receive(:execute_command).with("/usr/sbin/networksetup", "-listnetworkserviceorder").and_return(<<EOVPN
An asterisk (*) denotes that a network service is disabled.
  (1) Bluetooth DUN
(Hardware Port: Bluetooth DUN, Device: Bluetooth-Modem)

(2) Ethernet
(Hardware Port: Ethernet, Device: en0)

(3) VPN 1
(Hardware Port: IPSec, Device: )

(4) VPN 2
(Hardware Port: IPSec, Device: )

(5) VPAN 3
(Hardware Port: L2TP, Device: )
EOVPN
      )
    end

    describe "should return the correct list of the VPN and their statuses" do
      it "with no query" do
        expect(subject.perform_filtering("")).to eq([{name: "VPN 1", connected: false}, {name: "VPN 2", connected: true}, {name: "VPAN 3", connected: false}])
      end

      it "with query" do
        expect(subject.perform_filtering("VPN")).to eq([{name: "VPN 1", connected: false}, {name: "VPN 2", connected: true}])
        expect(subject.perform_filtering("3")).to eq([{name: "VPAN 3", connected: false}])
      end
    end
  end

  describe "#process_results" do
    it "should correctly prepare results" do
      expect(subject.process_results([{name: "VPN 1", connected: true}, {name: "VPN 2", connected: false}])).to eq([
        {title: "Disconnect from VPN 1", arg: "disconnect service \"VPN 1\"", subtitle: "Action this item to disconnect from the VPN service.", icon: Pincerna::Vpn::ICON},
        {title: "Connect to VPN 2", arg: "connect service \"VPN 2\"", subtitle: "Action this item to connect to the VPN service.", icon: Pincerna::Vpn::ICON}
      ])
    end
  end

  describe "#vpn_connected" do
    it "should return the correct connected status" do
      expect(subject).to receive(:execute_command).with("/usr/sbin/networksetup", "-showpppoestatus", "\"VPN\"").and_return("connected")
      expect(subject.vpn_connected?("VPN")).to be_true
    end

    it "should return false for other status" do
      expect(subject).to receive(:execute_command).with("/usr/sbin/networksetup", "-showpppoestatus", "\"VPN\"").and_return("other")
      expect(subject.vpn_connected?("VPN")).to be_false
    end
  end
end