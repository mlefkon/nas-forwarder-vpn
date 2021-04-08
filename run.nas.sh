#!/bin/bash

echo 'NAS Port Forwarder VPN'

if [ -n "$FORWARD_TCP_PORTS" ] && ! iptables -C FORWARD --jump DROP 2>/dev/null; then
    # Note: to make sure these get put before 'FORWARD --jump DROP', exec 'run.sh' afterwards.
    iptables -A FORWARD --in-interface eth0 --out-interface ppp0 --protocol tcp --syn --match multiport --dports "$FORWARD_TCP_PORTS" --match conntrack --ctstate NEW --jump ACCEPT
    iptables -A FORWARD --in-interface eth0 --out-interface ppp0 --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT
    iptables -A FORWARD --in-interface ppp0 --out-interface eth0 --match conntrack --ctstate ESTABLISHED,RELATED --jump ACCEPT
    iptables -t nat -A PREROUTING --in-interface eth0 --protocol tcp --match multiport --dports "$FORWARD_TCP_PORTS" --jump DNAT --to-destination 192.168.42.10
    iptables -t nat -A POSTROUTING --out-interface eth1 --protocol tcp --match multiport --dports "$FORWARD_TCP_PORTS" --destination 192.168.42.10 --jump SNAT --to-source 192.168.42.1

    echo "NAS forwarded ports have been applied to iptables."
fi;

/opt/src/run.sh
