if [ -z $1 ]
then
 echo "./proxy  DST_IP DST_PORT NEW_DST_IP NEW_DST_PORT"
 exit
fi


if [ -z $2 ]
then
 dstPort="443"
else 
 dstPort="$2"
fi

if [ -z $3 ]
then
 newdstIp="127.0.0.1"
else 
 newdstIp="$3"
fi


if [ -z $4 ]
then
 newdstPort="8080"
else 
 newdstPort="$4"
fi

dstIp="$1"



echo "Start filtering  $dstIp:$dstPort ==> $newdstIp:$newdstPort"

/sbin/iptables -I INPUT 1 -j ACCEPT -i enp0s9 -p tcp -m multiport --dports $newdstPort
/sbin/iptables -t nat -I PREROUTING  1 -i enp0s9 --dst $dstIp -p tcp  --dport $dstPort -j DNAT --to-destination $newdstIp:$newdstPort

###
#iptables -t nat -A PREROUTING -i enp0s8 --dst $dstIp  -p tcp --dport 80 -j DNAT --to $newdstIp:8080
#/sbin/iptables -I INPUT 1 -j ACCEPT -i enp0s9 -p tcp -m multiport --dports 8080
#/sbin/iptables -t nat -I PREROUTING  1 -i enp0s9 --dst 85.13.151.220 -p tcp -j DNAT --to-destination 127.0.0.1:8080