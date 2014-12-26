#!/bin/bash

if [ $META_NET_REMOTESEGMENTS ]; then
  for IPNetwork in $( echo $META_NET_REMOTESEGMENTS | tr ";" "\n" ); do
    route add -net $IPNetwork netmask $META_NET_MASK gw $META_NET_GATEWAY
  done
fi


export META_NET_MASTERSEGMENT="$( echo ${META_NET_REMOTESEGMENTS} | tr ";" "\n" | head -1 )"
export META_NODE_IP="$(ifconfig eth0 | awk -F ' *|:' '/inet addr/{print $4}')"


if [ ! -f /etc/confd/conf.d/supervisord.conf.toml ]; then
  if [ "$1" == "-join" ]; then
    touch /root/tmp/.joinConsulCluster

    export META_CONSUL_MASTERSERVERIP=$( nmap -p53 ${META_NET_MASTERSEGMENT}/24 | \
                                         grep -B 3 "53/tcp open  domain" | head -1 | tr " " "\n" | tail -1 )

    rm -f /etc/confd/conf.d/supervisord-primary.conf.toml
    rm -f /etc/confd/templates/supervisord-primary.conf.tmpl

    mv /etc/confd/conf.d/supervisord-secondary.conf.toml    /etc/confd/conf.d/supervisord.conf.toml
    mv /etc/confd/templates/supervisord-secondary.conf.tmpl /etc/confd/templates/supervisord.conf.tmpl
  else
    rm -f /etc/confd/conf.d/supervisord-secondary.conf.toml
    rm -f /etc/confd/templates/supervisord-secondary.conf.tmpl

    mv /etc/confd/conf.d/supervisord-primary.conf.toml      /etc/confd/conf.d/supervisord.conf.toml
    mv /etc/confd/templates/supervisord-primary.conf.tmpl   /etc/confd/templates/supervisord.conf.tmpl
  fi
fi


if [ -f /root/tmp/.joinConsulCluster ]; then
  export META_CONSUL_MASTERSERVERIP=$( nmap -p53 ${META_NET_MASTERSEGMENT}/24 | \
                                       grep -B 3 "53/tcp open  domain" | head -1 | tr " " "\n" | tail -1 )
fi


if [ -f /var/run/rsyslogd.pid                       ]; then rm -f /var/run/rsyslogd.pid                       ; fi
if [ -f /var/run/monit.pid                          ]; then rm -f /var/run/monit.pid                          ; fi
if [ -f /var/run/newrelic-daemon.pid                ]; then rm -f /var/run/newrelic-daemon.pid                ; fi
if [ -f /var/run/newrelic/newrelic-plugin-agent.pid ]; then rm -f /var/run/newrelic/newrelic-plugin-agent.pid ; fi
if [ -f /var/run/sshd.pid                           ]; then rm -f /var/run/sshd.pid                           ; fi
if [ -f /var/run/supervisord.pid                    ]; then rm -f /var/run/supervisord.pid                    ; fi

if [ -f /var/spool/postfix/pid/master.pid           ]; then rm -f /var/spool/postfix/pid/master.pid           ; fi
if [ -f /var/run/memcached.pid                      ]; then rm -f /var/run/memcached.pid                      ; fi
if [ -f /var/run/mysqld/mysqld.pid                  ]; then rm -f /var/run/mysqld/mysqld.pid                  ; fi
if [ -f /var/run/haproxy.pid                        ]; then rm -f /var/run/haproxy.pid                        ; fi
if [ -f /var/run/lsyncd.pid                         ]; then rm -f /var/run/lsyncd.pid                         ; fi
if [ -f /var/run/apache2/apache2.pid                ]; then rm -f /var/run/apache2/apache2.pid                ; fi


echo
echo "Boot time configuration dependencies:"
echo "  + META_NODE_NAME:             $META_NODE_NAME"
echo "  + META_NODE_IP:               $META_NODE_IP"
echo "  + META_NET_MASTERSEGMENT:     $META_NET_MASTERSEGMENT"
echo "  + META_CONSUL_MASTERSERVERIP: $META_CONSUL_MASTERSERVERIP"
echo


/usr/local/bin/confd -onetime
/usr/bin/supervisord