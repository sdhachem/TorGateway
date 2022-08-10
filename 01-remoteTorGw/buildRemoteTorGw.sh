#!/bin/sh

#https://www.digitalocean.com/community/tutorials/how-to-list-and-delete-iptables-firewall-rules
##### Stage 1 : Install required
echo "Build Ubuntu Gatway on remote server"
sudo apt-get -y install tor


#Disable ubuntu DNS 
echo "Disable ubuntu DNS "
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved	
rm -rf /etc/resolv.conf

hostName=`hostname` 
echo "127.0.0.1 $hostName">>"/etc/hosts"

#Instal tor
echo "Configure TOR "
sudo cp config/torrc /etc/tor/torrc

# Enable local forward on wg0
echo "Enable Local forwarding"
cp  config/myconf /etc/network/if-up.d/myconf
sudo chmod +x /etc/network/if-up.d/myconf
/sbin/sysctl -w net.ipv4.conf.wg0.route_localnet=1


##### Stage 2 : Iptables
echo "Stage 2 : Iptables "

chmod +x enableTorGw.sh
sudo cp enableTorGw.sh /root/

chmod +x disableTorGw.sh
sudo cp disableTorGw.sh /root/
