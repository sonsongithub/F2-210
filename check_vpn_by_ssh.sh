#!/bin/bash

result=$(ssh -q ubnt@192.168.10.1 'vbash -ic "show vpn ipsec status"')
count=$(echo "${result}" | awk '/([0-9]+) Active IPsec Tunnels/{print $1}')
echo "OK - ${count} users | users=${count}"