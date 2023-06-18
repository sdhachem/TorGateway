#!/bin/sh
VPN_PORT="443"

if [ -z $1 ]
then
 echo "./addNewVpnClient   ClientName CLIENT_VPN_IP SERVER_IP"
 exit
fi
if [ -z $2 ]
then
 echo "./addNewVpnClient   ClientName CLIENT_VPN_IP (in this subnet 10.200.0.1/24) SERVER_IP"
 exit
fi
if [ -z $3 ]
then
 echo "./addNewVpnClient   ClientName CLIENT_VPN_IP SERVER_IP"
 exit
fi

SERVER_WAN_IP="$3"

echo "Start adding the client $1 $2 $3"

echo "STEP 0 : Remove all files if there was a previous generation"
`rm -rf /etc/wireguard/clients/$1.*`

echo "STEP 1 : Generate new client private/public keys"
mkdir -p /etc/wireguard/clients; wg genkey |  tee /etc/wireguard/clients/$1.key | wg pubkey |  tee /etc/wireguard/clients/$1.key.pub

CLIENT_PUBLIC_KEY=`cat /etc/wireguard/clients/$1.key.pub`
echo "CLIENT_PUBLIC_KEY = $CLIENT_PUBLIC_KEY"

CLIENT_PRIVATE_KEY=`cat /etc/wireguard/clients/$1.key`
echo "CLIENT_PRIVATE_KEY = $CLIENT_PRIVATE_KEY"

SERVER_PUBLIC_KEY=`cat /etc/wireguard/keys/server.key.pub`
echo "SERVER_PUBLIC_KEY = $SERVER_PUBLIC_KEY"

echo "STEP 2 :Creation the client config /etc/wireguard/clients/$1.conf"
ClientConfFile="/etc/wireguard/clients/$1.conf"
echo "Client config file = $ClientConfFil"

echo "[Interface]" >> $ClientConfFile
echo "PrivateKey=$CLIENT_PRIVATE_KEY" >> $ClientConfFile
echo "Address = $2/32" >> $ClientConfFile
echo "DNS = 1.1.1.1, 1.0.0.1" >> $ClientConfFile
echo "" >> $ClientConfFile
echo "[Peer]" >> $ClientConfFile
echo "PublicKey = $SERVER_PUBLIC_KEY" >> $ClientConfFile
echo "AllowedIPs = 0.0.0.0/0" >> $ClientConfFile
echo "Endpoint = $SERVER_WAN_IP:$VPN_PORT" >> $ClientConfFile


echo "STEP 3 : Generate QR Code"
qrCodeFile="/etc/wireguard/clients/$1.png"
qrencode -t ansiutf8  -o $qrCodeFile -l H -v 2 <  $ClientConfFile
 
echo "STEP 3 : add the client to the server"
sudo wg set wg0 peer $CLIENT_PUBLIC_KEY allowed-ips $2

echo "End adding the client $1"
echo "Fetch New Client IP in $ClientConfFil"

