#!/bin/bash


filename="/var/tmp/route-domains"
tg=$1

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


	if [[ "$tg" -eq 1 ]]; then
	if [[ "$rd_num" -eq 1 || "$rd_num" -eq 2 ]]; then
	echo $tg $rd_num
	     tmsh run util imish -r $rd_num -f /config/monitors/custom/unset-prepend.cfg
	     /usr/sbin/vtysh -r $rd_num -e "clear ip bgp * soft out"

	fi
	fi

        if [[ "$tg" -eq 2 ]]; then
        if [[ "$rd_num" -eq 3 || "$rd_num" -eq 4 ]]; then
	echo $tg $rd_num
             tmsh run util imish -r $rd_num -f /config/monitors/custom/unset-prepend.cfg
             /usr/sbin/vtysh -r $rd_num -e "clear ip bgp * soft out"

        fi
        fi 

done < "$filename"


