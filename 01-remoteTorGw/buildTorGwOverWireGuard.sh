#!/bin/bash

VPN_PORT="443"
ServerConfFile="/etc/wireguard/wg0.conf"
PRIVATE_SERVER_SUBNET="10.300.0.1/24"

echo "Step 1 : Install tor and prepare the tunnel Wirguard ==> Tor"
sudo apt-get -y update && sudo apt-get -y upgrade

if [ -f /var/run/reboot-required ]; then
  echo 'reboot required : Run the script a'
  reboot now
  exit
fi

sudo apt-get -y install tor
sudo apt-get -y  install wireguard
sudo apt-get -y  install qrencode

#Disable ubuntu DNS 
echo "Disable ubuntu DNS "
hostName=`hostname` 

sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved	
rm -rf /etc/resolv.conf


echo "127.0.0.1 $hostName">>"/etc/hosts"

#Instal tor
echo "Configure TOR "
sudo cp config/torrc /etc/tor/torrc
sudo service tor restart

# Enable local forward on wg0
#echo "Enable Local forwarding"
#cp  config/myconf /etc/network/if-up.d/myconf
#sudo chmod +x /etc/network/if-up.d/myconf
#/sbin/sysctl -w net.ipv4.conf.wg0.route_localnet=1


##### Stage 2 : Iptables
echo "Stage 2 : Iptables "

chmod +x enableTorGw.sh
rm -rf /root/enableTorGw.sh 
sudo cp enableTorGw.sh /root/

chmod +x disableTorGw.sh
rm -rf /root/disableTorGw.sh
sudo cp disableTorGw.sh /root/


#install service
#sudo cp config/enableTorOnStart.service /etc/systemd/system/enableTorOnStart.service
#sudo systemctl enable enableTorOnStart
#sudo service enableTorOnStart restart


echo "Step 2 : Start installing WireGuard ==> $PRIVATE_SERVER_SUBNET"



#Remove the config File if it exists (reinstall)

sudo wg-quick down wg0  2> /dev/null
sudo systemctl stop wg-quick@wg0

sudo rm -rf $ServerConfFile 2> /dev/null
sudo rm -rf /etc/wireguard/keys 2> /dev/null

currentUser=`whoami` 
sudo chown -R $currentUser:$currentUser /etc/wireguard

DEFAULT_INTERFACE=`/usr/bin/ip -o -4 route show to default | /usr/bin/awk '{print $5}'` 
sudo mkdir -p /etc/wireguard/keys; /usr/bin/wg genkey | sudo tee /etc/wireguard/keys/server.key | wg pubkey | sudo tee /etc/wireguard/keys/server.key.pub

SERVER_PRIVATE_KEY=`cat /etc/wireguard/keys/server.key` 


echo "PrivateKey = $SERVER_PRIVATE_KEY"


echo "[Interface]" >> $ServerConfFile
echo "Address = $PRIVATE_SERVER_SUBNET" >> $ServerConfFile
echo "ListenPort = $VPN_PORT" >> $ServerConfFile
echo "PrivateKey = $SERVER_PRIVATE_KEY" >> $ServerConfFile
echo "PostUp = /root/enableTorGw.sh "  >> $ServerConfFile
echo "PostDown = /root/enableTorGw.sh"  >> $ServerConfFile
echo "SaveConfig = true" >> $ServerConfFile

sudo /usr/bin/chmod 600 /etc/wireguard/wg0.conf /etc/wireguard/keys/server.key
quickWgInfo=`sudo wg-quick up wg0`
echo "$quickWgInfo" 
ShowNewInterface=`sudo wg show wg0`
echo "ShowNewInterface ==> $ShowNewInterface"


sudo systemctl enable wg-quick@wg0

echo "Enable forwarding"
#sysctl -w net.ipv4.ip_forward=1 (Not persistent)
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p
#Check if it eabled
sudo sysctl net.ipv4.ip_forward

sudo sysctl -p
ResultForwardinCmd=`sysctl net.ipv4.ip_forward` 
echo "End enable forwarding : $ResultForwardinCmd"


sudo wg-quick down wg0  2> /dev/null
sudo systemctl restart wg-quick@wg0

sudo systemctl status wg-quick@wg0
sudo wg show wg0


