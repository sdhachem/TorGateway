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
 newdstIp="192.168.100.10"
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

#iptables -t nat -A PREROUTING -i enp0s8 --dst $dstIp  -p tcp --dport 80 -j DNAT --to $newdstIp:8080
iptables -t nat -A PREROUTING -i enp0s8 --dst $dstIp  -p tcp --dport $dstPort -j DNAT --to $newdstIp:$newdstPort
