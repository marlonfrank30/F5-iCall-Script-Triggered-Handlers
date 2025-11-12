#!/bin/bash


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
# for rd_num in 2; do

  imish -r $rd_num -e 'sh ip bgp neighbors | include local AS' | sed -n '/local AS /s/.*local AS //p' | tail -n 1 |  grep -o '[0-9]\+' | sort | uniq > /var/tmp/bgp-local-asn-rd$rd_num

	if [[ "$rd_num" -eq 1 || "$rd_num" -eq 2 ]]; then
        tmsh run /sys failover standby traffic-group traffic-group-1

		input_filename="/var/tmp/bgp-local-asn-rd$rd_num"
		read -r localas < "$input_filename"
		# echo "Local AS is: $localas"
		# sed -i 's/.*set as-path prepend.*/set as-path prepend/' set-prepend.cfg 
		sed -i '/set as-path prepend/d' /config/monitors/custom/set-prepend.cfg
		echo "set as-path prepend $localas" >> /config/monitors/custom/set-prepend.cfg
	#	echo "$(cat /config/monitors/custom/set-prepend.cfg) $localas" >/config/monitors/custom/set-prepend.cfg

	#   tmsh run util imish -r 2 -f /config/monitors/custom/set-prepend.cfg
	#        exec /usr/sbin/vtysh -r 2 -e "clear ip bgp * soft out"
	     tmsh run util imish -r $rd_num -f /config/monitors/custom/set-prepend.cfg
	     /usr/sbin/vtysh -r $rd_num -e "clear ip bgp * soft out"



	fi
        

done < "$filename"


