#!/bin/bash

#Script to hasten set up of tor directory authorities

read -p "We need to get the dependencies for TOR (y,n) " REPLY

if [ "${REPLY,,}" == "y" ]; then
	
	echo "Installing necessary dependencies..."	
	apt-get --force-yes install libevent-dev
	apt-get --force-yes install libssl-dev

fi

#Update/upgrade system
read -p "We need to update/upgrade the system (y,n) " REPLY

if [ "${REPLY,,}" == "y" ]; then
	
	apt-get update

#	apt-get dist-upgrade
fi

#Install Tor
read -p "Do you want to install Tor? (MAKE SURE YOU'RE 100% SURE ABOUT THIS! (y,n)" REPLY

if [ "${REPLY,,}" == "y" ]; then
	
	cd ~/home/Downloads/
	wget "https://www.torproject.org/dist/tor-0.2.8.8.tar.gz"
	tar -zxvf tor-0.2.8.8.tar.gz
	cd tor-0.2.8.8/
	./configure && make && make install
	mkdir /var/lib/tor
	touch /usr/local/etc/tor
  	mkdir /var/lib/tor/keys
	rm /usr/local/etc/tor/torrc
fi

#Set network as testing network and data directory
echo "TestingTorNetwork 1" >> /usr/local/etc/tor/torrc
echo "DataDirectory /var/lib/tor" >> /usr/local/etc/tor/torrc
echo "ConnLimit 60" >> /usr/local/etc/tor/torrc

#Customizing torrc to suit relay

#Nickname for Relay
read -p "Enter your desired nickname for your authority: " Name
echo "Nickname $Name" >> /usr/local/etc/tor/torrc

#Config lines and log files
echo "ShutdownWaitLength 0" >> /usr/local/etc/tor/torrc
echo "Log notice file /var/lib/tor/notice.log" >> /usr/local/etc/tor/torrc
echo "Log info file /var/lib/tor/info.log" >> /usr/local/etc/tor/torrc
echo "Log debug file /var/lib/tor/debug.log" >> /usr/local/etc/tor/torrc
echo "ProtocolWarnings 1" >> /usr/local/etc/tor/torrc
echo "SafeLogging 0" >> /usr/local/etc/tor/torrc
echo "DisableDebuggerAttachment 0" >> /usr/local/etc/tor/torrc

#ORPORT for Relay
read -p "Enter the port number you want ORPort to look at: " ORPort

#DirPort for Relay
read -p "Enter the port number you want DirPort to look at: " DirPort


#Address for Relay
read -p "Enter the IP address of the relay: " Address


#Generate Authority Keys
tor-gencert --create-identity-key -m 12 -a $Address:$DirPort -i /var/lib/tor/keys/authority_identity_key -s /var/lib/tor/keys/authority_signing_key -c /var/lib/tor/keys/authority_certificate

#Generate Router Keys
cd /var/lib/tor/keys/
tor --list-fingerprint --orport $ORPort --dirserver "x 127.0.0.1:1 ffffffffffffffffffffffffffffffffffffffff" --datadirectory /var/lib/tor/

#Add DirAuthority lines to config file
AuthCert="$(cat /var/lib/tor/keys/authority_certificate | grep 'fingerprint' | cut -f2- -d' ')"
AuthFinger="$(cat /var/lib/tor/fingerprint | cut -f2- -d' ')"
echo -e "DirAuthority $Name orport=$ORPort v3ident=$AuthCert $Address:$DirPort $AuthFinger" >> /usr/local/etc/tor/torrc

#Set Configuration stuff
echo >> /usr/local/etc/tor/torrc
echo "SocksPort 0" >> /usr/local/etc/tor/torrc
echo "ORPort $ORPort" >> /usr/local/etc/tor/torrc
echo "DirPort $DirPort" >> /usr/local/etc/tor/torrc
echo "Address $Address" >> /usr/local/etc/tor/torrc

#Set Authority and Testing Parameters
echo >> /usr/local/etc/tor/torrc
echo "AuthoritativeDirectory 1" >> /usr/local/etc/tor/torrc
echo "V3AuthoritativeDirectory 1" >>/usr/local/etc/tor/torrc
echo "TestingV3AuthInitialVotingInterval 300 seconds" >> /usr/local/etc/tor/torrc
echo "TestingV3AuthInitialVoteDelay 20 seconds" >> /usr/local/etc/tor/torrc
echo "TestingV3AuthInitialDistDelay 20 seconds" >> /usr/local/etc/tor/torrc

#Exit policy for Relay
echo "By default we do not allow exit policies for relays."
read -p "Should this node be an exit node? (y,n)" REPLY

echo "#Exit policy for IPv4 LAN" >> /usr/local/etc/tor/torrc

if [ "${REPLY,,}" == "y" ]; then
	
	echo "ExitPolicy accept 172.16.0.0/16:*" >> /usr/local/etc/tor/torrc
	echo "ExitPolicy accept 172.17.0.0/16:*" >> /usr/local/etc/tor/torrc
	echo "ExitPolicy accept 172.18.0.0/16:*" >> /usr/local/etc/tor/torrc
	echo "ExitPolicy accept 172.19.0.0/16:*" >> /usr/local/etc/tor/torrc
	echo "ExitPolicy accept [::1]:*" >> /usr/local/etc/tor/torrc
	echo "IPv6Exit 1" >> /usr/local/etc/tor/torrc
fi

if [ "${REPLY,,}" == "n" ]; then
	
	echo "ExitPolicy reject *:*" >> /usr/local/etc/tor/torrc
fi

#Contact i
