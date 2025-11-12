#!/bin/bash

filename="/var/tmp/route-domains"

# Check if the file exists
if [[ ! -f "$filename" ]]; then
    echo "Error: Input file '$filename' does not exist."
    exit 1
fi


# for ((rd_num=2; rd_num<=4; rd_num++)); do
# for rd_num in 2 4; do

while IFS= read -r rd_num; do
    # Process each line here
    echo "Processing route-domain: $rd_num"
    # You can perform other operations on "$rd_num" here

   imish -r $rd_num -e 'sh ip bgp neighbors | include BGP state =' > /var/tmp/bgp-status-rd$rd_num
   
   if grep -q -i "Established, up" /var/tmp/bgp-status-rd$rd_num; then
    #  echo "The pattern was found, bgp peer(s) Established, up"

    # fetch the F5 RD# local ASN

    imish -r $rd_num -e 'sh ip bgp neighbors | include local AS' | sed -n '/local AS /s/.*local AS //p' | tail -n 1 |  grep -o '[0-9]\+' | sort | uniq > /var/tmp/bgp-local-asn-rd$rd_num

	input_filename="/var/tmp/bgp-local-asn-rd$rd_num"
	read -r localas < "$input_filename"
	# echo "Local AS is: $localas"
	# sed -i 's/.*set as-path prepend.*/set as-path prepend/' set-prepend.cfg 
	sed -i '/set as-path prepend/d' /config/monitors/custom/set-prepend.cfg
	echo "set as-path prepend $localas" >> /config/monitors/custom/set-prepend.cfg
	# echo "$(cat /config/monitors/custom/set-prepend.cfg) $localas" >/config/monitors/custom/set-prepend.cfg
        rm -f /var/tmp/bgp-prepend-already-exists	
	imish -r $rd_num -e 'show route-map REDIST | include as-path prepend' > /var/tmp/bgp-prepend-already-exists
     	if [ -s /var/tmp/bgp-prepend-already-exists ]; then
	echo "lines exist"
	else
        	tmsh run util imish -r $rd_num -f /config/monitors/custom/set-prepend.cfg
        	/usr/sbin/vtysh -r $rd_num -e "clear ip bgp * soft out"
        fi
    
    fi        

done < "$filename"


