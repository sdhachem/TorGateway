
echo "Build Ubuntu Gatway"

#Create user tor andremove the other users
#sudo adduser tor

#Requirements
echo "Install requirements .... "
sudo apt-get -y install isc-dhcp-server
sudo apt-get -y install tor

echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt-get -y install iptables-persistent

echo "Configure Network Interfaces .... "
#sudo cp config/interfaces /etc/network/interfaces
sudo cp config/01-network-manager-all.yaml /etc/netplan/01-network-manager-all.yaml
sudo netplan apply


echo "Enable forwarding"
#Enable port forwarding
#echo "Enable forwarding" : Not sure it is necessary
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p
sudo sysctl net.ipv4.ip_forward


echo "Install DHCP server"
sudo cp config/isc-dhcp-server /etc/default/isc-dhcp-server
sudo cp config/dhcpd.conf /etc/dhcp/dhcpd.conf
sudo service isc-dhcp-server restart



echo "Enable Local forwarding"
cp config/myconf /etc/network/if-up.d/myconf
sudo chmod +x /etc/network/if-up.d/myconf


#Disable ubuntu DNS 
echo "Disable ubuntu DNS "
sudo systemctl disable systemd-resolved
sudo systemctl stop systemd-resolved	
rm /etc/resolv.conf


#Instal tor
echo "Configure TOR "
sudo cp config/torrc /etc/tor/torrc
service tor restart


# Run the TOR IPTables stuff
echo "Forward taraffic to TOR"
chmod +x 02-EnableTorProxy.sh
./02-EnableTorProxy.sh

# Save the iptables & Persiste it
sudo /sbin/iptables-save > /etc/iptables/rules.v4
cp config/rc.local /etc/rc.local

: <<'END'
chmod +x ../tools/03-EnableTransparentProxy.sh
../tools/03-EnableTransparentProxy.sh
END
#sudo netplan apply
#sudo service NetworkManager restart
sudo service isc-dhcp-server restart

echo "Gateway created succefully"

echo "System will reboot"

reboot
