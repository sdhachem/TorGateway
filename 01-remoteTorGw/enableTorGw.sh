#!/bin/sh

sudo service tor restart

DEFAULT_INTERFACE=`/usr/bin/ip -o -4 route show to default | /usr/bin/awk '{print $5}'` 

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



#INTERNAL_INTERFACE (wg0) : Configure the VPN inteface 
/sbin/iptables -t nat -A OUTPUT -o wg0 -j RETURN
/sbin/iptables -t nat -A PREROUTING -i wg0 -d 10.0.0.0/8 -j RETURN
/sbin/iptables -t nat -A PREROUTING -i wg0 -d 192.168.0.0/16 -j RETURN
/sbin/iptables -t nat -A PREROUTING -i wg0  -j RETURN

#Accept input for traffic already established
/sbin/iptables -A INPUT -j ACCEPT -i wg0 -p tcp -m state --state ESTABLISHED
/sbin/iptables -A INPUT -j ACCEPT -i wg0 -p udp -m state --state ESTABLISHED,RELATED

#Accept all output from wg0
/sbin/iptables -A OUTPUT -j ACCEPT -o wg0


#Forward traffic to TOR : #sysctl -w net.ipv4.conf.wg0.route_localnet=1 ==> This is required to have this working
/sbin/iptables -A INPUT -j ACCEPT -i wg0 -p tcp -m multiport --dports 9090
/sbin/iptables -t nat -I PREROUTING  -i wg0 -p tcp -j DNAT --to-destination 127.0.0.1:9090


#Forwaord UDP Traffic to localhost 53
/sbin/iptables -A INPUT -j ACCEPT -i wg0 -p udp -m multiport --dports 53
/sbin/iptables -t nat -I PREROUTING  -i wg0 -p udp -j DNAT --to-destination 127.0.0.1:53


# Enable vpn and restart the gateway
#/usr/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Save the iptables & Persiste it
#service iptables save
#sudo /sbin/iptables-save > /etc/iptables/tor.v4
#cp config/rc.local /etc/rc.local

echo "End stage 2 "

