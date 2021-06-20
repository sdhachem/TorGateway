 sudo iptables -A FORWARD -i enp0s8 -o enp0s3 -j ACCEPT
 sudo iptables -A FORWARD -i enp0s3 -o enp0s8 -m state --state ESTABLISHED,RELATED -j ACCEPT
 sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
