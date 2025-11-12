#!/bin/bash

cmiStatus=`cat /var/prompt/cmiSyncStatus`
echo $cmiStatus

state=`cat /var/prompt/ps1`
echo $state

sleep 10

if [[ "$cmiStatus" == "In Sync" && "$state" == "ForcedOffline" ]] ; then
                tmsh run /sys failover online
		sleep 10
		tmsh run /sys failover standby
		logger -p local0.notice "Bringing cm status to online due to connected and in-sync state"

		if test -f "/var/tmp/bgp-peers-down"; then
		 rm -f /var/tmp/bgp-peers-down
		fi
fi
