#!/bin/sh
VPN_PORT="443"

if [ -z $1 ]
then
 echo "./addNewVpnClient   ClientName  SERVER_IP"
 exit
fi
if [ -z $2 ]
then
 echo "./addNewVpnClient   ClientName  SERVER_IP"
 exit
fi

SERVER_WAN_IP="$2"

echo "Start adding the client $1 10.300.0.1 $2"

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
echo "Address = 10.300.0.1/32" >> $ClientConfFile
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
sudo wg set wg0 peer $CLIENT_PUBLIC_KEY allowed-ips 10.300.0.1

echo "End adding the client $1 : Fetch the config file from $ClientConfFile"


