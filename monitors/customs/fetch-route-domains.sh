#!/bin/bash

tmsh list net route-domain one-line | grep BGP > /var/tmp/input-rd
# sed -i '1d' /var/tmp/input-rd
sed -n 's/.* \([0-9]\).*/\1/p' /var/tmp/input-rd > /var/tmp/route-domains; rm -f /var/tmp/input-rd
sed -i '/0/d' /var/tmp/route-domains




