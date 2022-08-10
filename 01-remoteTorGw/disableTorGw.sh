#https://www.digitalocean.com/community/tutorials/how-to-list-and-delete-iptables-firewall-rules

sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -F
sudo iptables -X

#/usr/sbin/iptables -A FORWARD -i wg0 -j ACCEPT
#/usr/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

/sbin/iptables-restore < /etc/iptables/rules.v4

sudo service tor stop
sudo systemctl start systemd-resolved	