#!/bin/sh

# Prepare for element
sudo wget -O /usr/share/keyrings/element-io-archive-keyring.gpg https://packages.element.io/debian/element-io-archive-keyring.gpg
‍
echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] https://packages.element.io/debian/ default main" | sudo tee /etc/apt/sources.list.d/element-io.list

#create user
adduser --disabled-password --gecos "" live


#Configure TOR
echo "Start  TOR Srvice deployment .............. "

# stop local dns
echo "Disable local DNS to use TOR for DNS"
sudo systemctl stop systemd-resolved	
sudo systemctl stop connman
sudo systemctl disable systemd-resolved	
sudo systemctl disable connman
rm -rf /etc/resolv.conf

hostName=`hostname`
echo "127.0.0.1 $hostName">>"/etc/hosts"

echo "Configure TOR "
cp /opt/tor/release/config/torrc /etc/tor/torrc
sudo service tor restart

cp /opt/tor/release/HowToConnectToWifi.txt /home/live/Desktop/

echo "Persist iptables rules on interface up"
cp  /opt/tor/release/enableTorGw.sh  /etc/network/if-up.d/enableTorGw.sh
chmod a+x /etc/network/if-up.d/enableTorGw.sh

echo "Enable Local forwarding"
DEFAULT_INTERFACE=`/usr/bin/ip -o -4 route show to default | /usr/bin/awk '{print $5}'` 
/sbin/sysctl -w net.ipv4.conf.$DEFAULT_INTERFACE.route_localnet=1

echo "Check the install"
ls -l /opt/tor
ls -l /opt/tor/release
ls -l /etc/resolv.conf
cat /etc/hosts
sudo systemctl status systemd-resolved	
sudo systemctl status connman


