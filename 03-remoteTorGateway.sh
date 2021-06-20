#!/bin/sh


#######
## 
## How to build Tor Gateway on Ubuntu :
## 
## 0. Configure Ubuntu with two interface and DHCP runing on one of them : https://www.thomaslaurenson.com/blog/2018-07-05/building-an-ubuntu-linux-gateway/
##  	enp0s3 : External interface (10.0.2.15/24)
##  	enp0s8 : VPN interface (192.168.100.10/24)
##
##		Disable ubuntu DNS :
##			sudo systemctl disable systemd-resolved
##			sudo systemctl stop systemd-resolved	
##			rm /etc/resolv.conf
##			
##			
## 1. Install tor : apt-get install tor
## 2. Add the following in /etc/tor/torrc
## 			SocksPort 9050 IsolateDestAddr IsolateDestPort
## 			TransPort 9090 IsolateDestAddr IsolateDestPort
## 			
## 			DNSPort 53
## 			AutomapHostsOnResolve 1
## 			AutomapHostsSuffixes .exit,.onion
## 3. Add  /sbin/sysctl -w net.ipv4.conf.enp0s8.route_localnet=1 in startup :Follow this to persiste : https://askubuntu.com/questions/41400/how-do-i-make-the-script-to-run-automatically-when-tun0-interface-up-down-events

##		nano /etc/network/if-up.d/myconf
##		sudo chmod +x /etc/network/if-up.d/myconf
##		
##	Put the below script
##			#!/bin/sh
##			if [ "$IFACE" = enp0s8 ]; then
##			  /sbin/sysctl -w net.ipv4.conf.enp0s8.route_localnet=1
##			fi


## 4. Run this script and persiste iptable
##		sudo apt-get install iptables-persistent
##		sudo iptables-persistent save 
##		
##		sudo systemctl is-enabled netfilter-persistent.service
##		sudo systemctl enable netfilter-persistent.service
##		
## Enjoy every thing in TOR : tcp & DNS
##
##
######

_tor_uid=`id -u debian-tor`

#Cleaning
/sbin/iptables -F
/sbin/iptables -t nat -F
/sbin/iptables -t mangle -F
/sbin/iptables -X
/sbin/iptables -P INPUT DROP
/sbin/iptables -P OUTPUT DROP
/sbin/iptables -P FORWARD DROP

/sbin/iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 10/s -j ACCEPT

/sbin/iptables -t nat -A OUTPUT -m owner --uid-owner $_tor_uid -j RETURN
/sbin/iptables -t nat -A OUTPUT -p udp -m multiport --dports 123 -j RETURN
/sbin/iptables -t nat -A OUTPUT -o lo -j RETURN
/sbin/iptables -t nat -A OUTPUT -d 192.168.0.0/16 -j RETURN
/sbin/iptables -t nat -A OUTPUT -d 10.0.0.0/8 -j RETURN
/sbin/iptables -t nat -A OUTPUT -p tcp -d 1.1.1.1 --dport 853 -j RETURN
/sbin/iptables -t nat -A OUTPUT -p tcp -d 1.0.0.1 --dport 853 -j RETURN

/sbin/iptables -A INPUT -j ACCEPT -i lo
/sbin/iptables -A OUTPUT -j ACCEPT -o lo


#Allow all incoming traffic on already estabilished connections 
/sbin/iptables -A INPUT -j ACCEPT -i enp0s3 -p tcp -m state --state ESTABLISHED
/sbin/iptables -A INPUT -j ACCEPT -i enp0s3 -p udp -m state --state ESTABLISHED,RELATED
/sbin/iptables -A INPUT -j ACCEPT -i enp0s3 -p icmp -m state --state ESTABLISHED


#Allow Outgoing traffic already established
/sbin/iptables -A OUTPUT -j ACCEPT -o enp0s3 -p tcp -m state --state ESTABLISHED
/sbin/iptables -A OUTPUT -j ACCEPT -o enp0s3 -p udp -m state --state ESTABLISHED,RELATED
/sbin/iptables -A OUTPUT -j ACCEPT -o enp0s3 -p icmp -m state --state ESTABLISHED


#Allow SSH From the Host to the Guest
/sbin/iptables -A INPUT -j ACCEPT -i enp0s3 -p tcp -m multiport --dports 22
/sbin/iptables -A OUTPUT -j ACCEPT -o enp0s3 -d 10.0.0.0/8  -p tcp --sport 22


#Allow Outgoing traffic initiated by TOR only
/sbin/iptables -A OUTPUT -j ACCEPT -o enp0s3 -m owner --uid-owner $_tor_uid -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m state --state NEW --dport 443

#Socks port not used
#/sbin/iptables -A OUTPUT -j ACCEPT -o enp0s3 -p tcp --syn --dport 9050 -d 127.0.0.1/32


#Forward all tcp traffic to Transparent Port
/sbin/iptables -A OUTPUT -j ACCEPT -o enp0s3 -p tcp --syn --dport 9090 -d 127.0.0.1/32
/sbin/iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9090 


#Forward DNS traffic to DNS Port : Nothing needed since TOR DNS is listning on 53


#INTERNAL_INTERFACE : Configure the internal inteface : To review
/sbin/iptables -t nat -A OUTPUT -o enp0s8 -j RETURN
/sbin/iptables -t nat -A PREROUTING -i enp0s8 -d 10.0.0.0/8 -j RETURN
/sbin/iptables -t nat -A PREROUTING -i enp0s8 -d 192.168.0.0/16 -j RETURN
/sbin/iptables -t nat -A PREROUTING -i enp0s8  -j RETURN

#Accept input for traffic already established
/sbin/iptables -A INPUT -j ACCEPT -i enp0s8 -p tcp -m state --state ESTABLISHED
/sbin/iptables -A INPUT -j ACCEPT -i enp0s8 -p udp -m state --state ESTABLISHED,RELATED

#Accept all output from enp0s8
/sbin/iptables -A OUTPUT -j ACCEPT -o enp0s8


#Forward traffic to TOR : #sysctl -w net.ipv4.conf.enp0s8.route_localnet=1 ==> This is required to have this working
/sbin/iptables -A INPUT -j ACCEPT -i enp0s8 -p tcp -m multiport --dports 9090
iptables -t nat -I PREROUTING  -i enp0s8 -p tcp -j DNAT --to-destination 127.0.0.1:9090


#Forwaord UDP Traffic to localhost 53
/sbin/iptables -A INPUT -j ACCEPT -i enp0s8 -p udp -m multiport --dports 53
/sbin/iptables -t nat -I PREROUTING  -i enp0s8 -p udp -j DNAT --to-destination 127.0.0.1:53





