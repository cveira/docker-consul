#!/bin/bash

if [ $META_NET_REMOTESEGMENTS ]; then
  for IPNetwork in $( echo $META_NET_REMOTESEGMENTS | tr ";" "\n" ); do
    route add -net $IPNetwork netmask $META_NET_MASK gw $META_NET_GATEWAY
  done
fi


export META_SERVER_IP="$(ifconfig eth0 | awk -F ' *|:' '/inet addr/{print $4}')"
export META_CONSUL_PARAMS="$@"

case "$( echo '$@' | tr '-' '\n' | grep 'join' | wc -l )" in
  "1")
    export META_CONSUL_MASTER=$( nmap -p53 ${META_NET_MASTERSEGMENT}/24 | \
                                 grep -B 3 "53/tcp open  domain" | head -1 | tr " " "\n" | tail -1 )

    sed -i "s/{META_SERVER_IP}/${META_SERVER_IP}/g"         /etc/supervisor/conf.d/supervisord-secondary.conf
    sed -i "s/{META_CONSUL_MASTER}/${META_CONSUL_MASTER}/g" /etc/supervisor/conf.d/supervisord-secondary.conf

    /usr/local/bin/confd -onetime
    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord-secondary.conf
    ;;
  *)
    sed -i "s/{META_SERVER_IP}/${META_SERVER_IP}/g"         /etc/supervisor/conf.d/supervisord-primary.conf

    /usr/local/bin/confd -onetime
    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord-primary.conf
    ;;
esac