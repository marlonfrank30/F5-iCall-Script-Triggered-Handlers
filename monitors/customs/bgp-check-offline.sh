#!/bin/bash


sleep 10

nr_lines=$(wc -l < /var/tmp/bgp-peers-down)
if [ $nr_lines -ge 2 ]; then
	tmsh run /sys failover offline
 	logger -p local0.notice "Bringing cm status to offline due to multiple bgp peers are down"
fi

if test -f "/var/tmp/bgp-peers-down"; then
 rm -f /var/tmp/bgp-peers-down
fi

