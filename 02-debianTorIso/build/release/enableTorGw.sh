#!/bin/sh

sudo systemctl stop systemd-resolved	
sudo systemctl stop connman


DEFAULT_INTERFACE=`/usr/bin/ip -o -4 route show to default | /usr/bin/awk '{print $5}'` 


_tor_uid=`id -u debian-tor`
sudo service tor restart

#Cleaning

sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -F
sudo iptables -X


/sbin/iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 10/s -j ACCEPT

/sbin/iptables -t nat -A OUTPUT -m owner --uid-owner $_tor_uid -j RETURN
/sbin/iptables -t nat -A OUTPUT -p udp -m multiport --dports 123 -j RETURN
/sbin/iptables -t nat -A OUTPUT -o lo -j RETURN
/sbin/iptables -t nat -A OUTPUT -d 192.168.0.0/16 -j RETURN
/sbin/iptables -t nat -A OUTPUT -d 10.0.0.0/8 -j RETURN
/sbin/iptables -t nat -A OUTPUT -p tcp -d 1.1.1.1 --dport 853 -j RETURN
/sbin/iptables -t nat -A OUTPUT -p tcp -d 1.0.0.1 --dport 853 -j RETURN


#Allow LocalHost 
/sbin/iptables -A INPUT -j ACCEPT -i lo
/sbin/iptables -A OUTPUT -j ACCEPT -o lo


#Allow all incoming traffic on already estabilished connections 
/sbin/iptables -A INPUT -j ACCEPT -i $DEFAULT_INTERFACE -p tcp -m state --state ESTABLISHED
/sbin/iptables -A INPUT -j ACCEPT -i $DEFAULT_INTERFACE -p udp -m state --state ESTABLISHED,RELATED
/sbin/iptables -A INPUT -j ACCEPT -i $DEFAULT_INTERFACE -p icmp -m state --state ESTABLISHED


#Allow Outgoing traffic already established
/sbin/iptables -A OUTPUT -j ACCEPT -o $DEFAULT_INTERFACE -p tcp -m state --state ESTABLISHED
/sbin/iptables -A OUTPUT -j ACCEPT -o $DEFAULT_INTERFACE -p udp -m state --state ESTABLISHED,RELATED
/sbin/iptables -A OUTPUT -j ACCEPT -o $DEFAULT_INTERFACE -p icmp -m state --state ESTABLISHED


#Allow SSH From the Host to the Guest on management interface
/sbin/iptables -A INPUT -j ACCEPT -i $DEFAULT_INTERFACE -p tcp -m multiport --dports 22
/sbin/iptables -A OUTPUT -j ACCEPT -o $DEFAULT_INTERFACE -d 10.0.0.0/8  -p tcp --sport 22


#Allow Outgoing traffic initiated by TOR only
/sbin/iptables -A OUTPUT -j ACCEPT -o $DEFAULT_INTERFACE -m owner --uid-owner $_tor_uid -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m state --state NEW --dport 443

#Socks port not used
#/sbin/iptables -A OUTPUT -j ACCEPT -o $DEFAULT_INTERFACE -p tcp --syn --dport 9050 -d 127.0.0.1/32


#Forward all tcp traffic to Transparent Port
/sbin/iptables -A OUTPUT -j ACCEPT -o $DEFAULT_INTERFACE -p tcp --syn --dport 9090 -d 127.0.0.1/32
/sbin/iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9090 


#Forward DNS traffic to DNS Port : Nothing needed since TOR DNS is listning on 53

echo "End enableTorGw "

