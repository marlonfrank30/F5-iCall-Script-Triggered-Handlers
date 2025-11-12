#!/bin/bash

cmiStatus=`cat /var/prompt/cmiSyncStatus`
echo $cmiStatus

state=`cat /var/prompt/ps1`
echo $state

sleep 5

if [[ "$cmiStatus" == "In Sync" && "$state" == "ForcedOffline" ]] ; then
                tmsh run /sys failover online
                sleep 10
                tmsh run /sys failover standby
                logger -p local0.notice "Bringing cm status to online due to connected and in-sync state"
fi

tmsh list net route-domain one-line | grep BGP > /var/tmp/input-rd
# sed -i '1d' /var/tmp/input-rd
sed -n 's/.* \([0-9]\).*/\1/p' /var/tmp/input-rd > /var/tmp/route-domains; rm -f /var/tmp/input-rd
sed -i '/0/d' /var/tmp/route-domains

filename="/var/tmp/route-domains"

# Check if the file exists
if [[ ! -f "$filename" ]]; then
    echo "Error: Input file '$filename' does not exist."
    exit 1
fi

while IFS= read -r rd_num; do
    # Process each line here
    echo "Processing route-domain: $rd_num"
    # You can perform other operations on "$rd_num" here

# for ((rd_num=1; rd_num<=4; rd_num++)); do
# for rd_num in 2 4; do

sleep 5 

    imish -r $rd_num -e 'sh ip bgp neighbors | include local AS' | sed -n '/local AS /s/.*local AS //p' | tail -n 1 |  grep -o '[0-9]\+' | sort | uniq > /var/tmp/bgp-local-asn-rd$rd_num
        input_filename="/var/tmp/bgp-local-asn-rd$rd_num"
        read -r localas < "$input_filename"
        # echo "Local AS is: $localas"
        # sed -i 's/.*set as-path prepend.*/set as-path prepend/' set-prepend.cfg 
        sed -i '/set as-path prepend/d' /config/monitors/custom/set-prepend.cfg
        echo "set as-path prepend $localas" >> /config/monitors/custom/set-prepend.cfg
        # echo "$(cat /config/monitors/custom/set-prepend.cfg) $localas" >/config/monitors/custom/set-prepend.cfg
        tmsh run util imish -r $rd_num -f /config/monitors/custom/set-prepend.cfg
        /usr/sbin/vtysh -r $rd_num -e "clear ip bgp * soft out"
        tmsh run /sys failover standby

done < "$filename"
