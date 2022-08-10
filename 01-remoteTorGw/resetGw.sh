sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -F
sudo iptables -X

/usr/sbin/iptables -A FORWARD -i wg0 -j ACCEPT
/usr/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

sudo service tor stop
sudo systemctl start systemd-resolved	