
echo "Reset the IPTable"
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables  -P OUTPUT ACCEPT
#sudo iptables -t nat

#Reset the iptabele

#1. Remove forward to transparent proxy
## NAT interface
sudo iptables -D OUTPUT -j ACCEPT -o enp0s3 -p tcp --syn --dport 9090 -d 127.0.0.1/32

sudo iptables -F
sudo iptables -t nat -F


echo "Create transparent proxy (Not persisted)"

sudo iptables -A FORWARD -i enp0s8 -o enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o enp0s8 -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE


sudo iptables -A FORWARD -i enp0s8 -o enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o enp0s8 -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE


#Continue to send the udp traffic coming from internal interface to tor
#Interface enp0s8
/sbin/iptables -A INPUT -j ACCEPT -i enp0s8 -p udp -m multiport --dports 53
/sbin/iptables -t nat -I PREROUTING  -i enp0s8 -p udp -j DNAT --to-destination 127.0.0.1:53

#Interface enp0s9
/sbin/iptables -A INPUT -j ACCEPT -i enp0s9 -p udp -m multiport --dports 53
/sbin/iptables -t nat -I PREROUTING  -i enp0s9 -p udp -j DNAT --to-destination 127.0.0.1:53





