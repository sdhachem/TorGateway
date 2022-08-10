#!/bin/sh
VPN_PORT="443"
ServerConfFile="/etc/wireguard/wg0.conf"

if [ -z $1 ]
then
 echo "./installWireGuard PRIVATE_SERVER_SUBNET (10.10.10.10/24)"
 exit
fi

echo "Step 1 : Install tor and prepare the tunnel Wirguard ==> Tor"
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

echo "Step 2 : Start installing WireGuard ==> $PRIVATE_SERVER_SUBNET"
PRIVATE_SERVER_SUBNET=$1 


#Remove the config File if it exists (reinstall)
sudo wg-quick down wg0  2> /dev/null
sudo rm -rf $ServerConfFile 2> /dev/null
sudo rm -rf /etc/wireguard/keys 2> /dev/null

sudo apt-get -y  install wireguard


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
echo "PostDown = /root/disableTorGw.sh"  >> $ServerConfFile
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




