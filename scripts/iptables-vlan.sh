#!/bin/bash

SYSCTL="/sbin/sysctl -w"

IPT="/sbin/iptables"
IPTS="/sbin/iptables-save"
IPTR="/sbin/iptables-restore"

# Internet Interface
INET_IFACE="eth1"
INET_IP="1.2.3.4"
INET_ADMIN="2.3.4.5"

VPN_IFACE="tun+"
VPN_IP="10.8.0.1"
VPN_NET="10.8.0.0/8"
VPN_BCAST="10.255.255.255"

# Local Interface Information
LOCAL_IFACE="eth0"
LOCAL_IP="192.168.5.1"
LOCAL_NET="192.168.5.0/24"
LOCAL_BCAST="192.168.5.255"

EVOIP_IFACE="vlan1234"
EVOIP_IP="10.20.5.50"
EVOIP_NET="10.20.5.48/29"
EVOIP_BCAST="10.20.5.55"

VIDEO_IFACE="vlan1015"
VIDEO_IP="192.168.15.1"
VIDEO_NET="192.168.15.0/24"
VIDEO_BCAST="192.168.15.255"

VOIP_IFACE="vlan1016"
VOIP_IP="192.168.16.1"
VOIP_NET="192.168.16.0/24"
VOIP_BCAST="192.168.16.255"

WIFI_IFACE="vlan1017"
WIFI_IP="192.168.17.1"
WIFI_NET="192.168.17.0/24"
WIFI_BCAST="192.168.17.255"

# Localhost Interface

LO_IFACE="lo"
LO_IP="127.0.0.1"

# Save and Restore arguments handled here
if [ "$1" = "save" ]
then
        echo -n "Saving firewall to /etc/sysconfig/iptables ... "
        $IPTS > /etc/scripts/iptables
        echo "done"
        exit 0
elif [ "$1" = "restore" ]
then
        echo -n "Restoring firewall from /etc/sysconfig/iptables ... "
        $IPTR < /etc/scripts/iptables
        echo "done"
        exit 0
fi

echo "Loading kernel modules ..."

/sbin/modprobe ip_tables
/sbin/modprobe ip_conntrack
/sbin/modprobe iptable_filter
/sbin/modprobe iptable_mangle
/sbin/modprobe iptable_nat
/sbin/modprobe ipt_LOG
/sbin/modprobe ipt_limit
/sbin/modprobe ipt_MASQUERADE
#/sbin/modprobe ipt_owner
#/sbin/modprobe ipt_REJECT
#/sbin/modprobe ipt_mark
#/sbin/modprobe ipt_tcpmss
/sbin/modprobe multiport
/sbin/modprobe ipt_state
#/sbin/modprobe ipt_unclean
/sbin/modprobe ip_nat_ftp
/sbin/modprobe ip_conntrack_ftp
#/sbin/modprobe ip_conntrack_irc

if [ "$SYSCTL" = "" ]
then
    echo "1" > /proc/sys/net/ipv4/ip_forward
else
    $SYSCTL net.ipv4.ip_forward="1"
fi

if [ "$SYSCTL" = "" ]
then
    echo "1" > /proc/sys/net/ipv4/tcp_syncookies
else
    $SYSCTL net.ipv4.tcp_syncookies="1"
fi

if [ "$SYSCTL" = "" ]
then
    echo "1" > /proc/sys/net/ipv4/conf/all/rp_filter
else
    $SYSCTL net.ipv4.conf.all.rp_filter="1"
fi

if [ "$SYSCTL" = "" ]
then
    echo "1" > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
else
    $SYSCTL net.ipv4.icmp_echo_ignore_broadcasts="1"
fi

if [ "$SYSCTL" = "" ]
then
    echo "0" > /proc/sys/net/ipv4/conf/all/accept_source_route
else
    $SYSCTL net.ipv4.conf.all.accept_source_route="0"
fi

if [ "$SYSCTL" = "" ]
then
    echo "1" > /proc/sys/net/ipv4/conf/all/secure_redirects
else
    $SYSCTL net.ipv4.conf.all.secure_redirects="1"
fi

if [ "$SYSCTL" = "" ]
then
    echo "1" > /proc/sys/net/ipv4/conf/all/log_martians
else
    $SYSCTL net.ipv4.conf.all.log_martians="1"
fi

###############################################################################
echo "Flushing Tables ..."

# Reset Default Policies
$IPT -P INPUT ACCEPT
$IPT -P FORWARD ACCEPT
$IPT -P OUTPUT ACCEPT
$IPT -t nat -P PREROUTING ACCEPT
$IPT -t nat -P POSTROUTING ACCEPT
$IPT -t nat -P OUTPUT ACCEPT
$IPT -t mangle -P PREROUTING ACCEPT
$IPT -t mangle -P OUTPUT ACCEPT

$IPT -F
$IPT -t nat -F
$IPT -t mangle -F
$IPT -X
$IPT -t nat -X
$IPT -t mangle -X

if [ "$1" = "stop" ]
then
        echo "Firewall completely flushed!  Now running with no firewall."
        exit 0
fi

$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP
###############################################################################

#$IPT -N bad_packets
#$IPT -N bad_tcp_packets
$IPT -N icmp_packets
$IPT -N udp_inbound
$IPT -N udp_outbound
$IPT -N tcp_inbound
$IPT -N tcp_outbound

#$IPT -A bad_packets -p ALL -i $INET_IFACE -s $LOCAL_NET -j LOG --log-prefix "fp=bad_packets:2 a=DROP "
$IPT -A bad_packets -p ALL -i $INET_IFACE -s $LOCAL_NET -j DROP
#$IPT -A bad_packets -p ALL -m state --state INVALID -j LOG --log-prefix "fp=bad_packets:1 a=DROP "
$IPT -A bad_packets -p ALL -m state --state INVALID -j DROP
$IPT -A bad_packets -p tcp -j bad_tcp_packets
$IPT -A bad_packets -p ALL -j RETURN

$IPT -A bad_tcp_packets -p tcp -i $LOCAL_IFACE -j RETURN
#$IPT -A bad_tcp_packets -p tcp ! --syn -m state --state NEW -j LOG --log-prefix "fp=bad_tcp_packets:1 a=DROP "
$IPT -A bad_tcp_packets -p tcp ! --syn -m state --state NEW -j DROP
#$IPT -A bad_tcp_packets -p tcp --tcp-flags ALL NONE -j LOG --log-prefix "fp=bad_tcp_packets:2 a=DROP "
$IPT -A bad_tcp_packets -p tcp --tcp-flags ALL NONE -j DROP
#$IPT -A bad_tcp_packets -p tcp --tcp-flags ALL ALL -j LOG --log-prefix "fp=bad_tcp_packets:3 a=DROP "
$IPT -A bad_tcp_packets -p tcp --tcp-flags ALL ALL -j DROP
#$IPT -A bad_tcp_packets -p tcp --tcp-flags ALL FIN,URG,PSH -j LOG --log-prefix "fp=bad_tcp_packets:4 a=DROP "
$IPT -A bad_tcp_packets -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
#$IPT -A bad_tcp_packets -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j LOG --log-prefix "fp=bad_tcp_packets:5 a=DROP "
$IPT -A bad_tcp_packets -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
#$IPT -A bad_tcp_packets -p tcp --tcp-flags SYN,RST SYN,RST -j LOG --log-prefix "fp=bad_tcp_packets:6 a=DROP "
$IPT -A bad_tcp_packets -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
#$IPT -A bad_tcp_packets -p tcp --tcp-flags SYN,FIN SYN,FIN -j LOG --log-prefix "fp=bad_tcp_packets:7 a=DROP "
$IPT -A bad_tcp_packets -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
$IPT -A bad_tcp_packets -p tcp -j RETURN

#$IPT -A icmp_packets --fragment -p ICMP -j LOG --log-prefix "fp=icmp_packets:1 a=DROP "
$IPT -A icmp_packets --fragment -p ICMP -j DROP
$IPT -A icmp_packets -p ICMP -s 0/0 --icmp-type 8 -j DROP
$IPT -A icmp_packets -p ICMP -s 0/0 --icmp-type 11 -j ACCEPT
$IPT -A icmp_packets -p ICMP -j RETURN
#$IPT -A icmp_packets -p ICMP -j ACCEPT

$IPT -A udp_inbound -p UDP -s 0/0 --destination-port 137 -j DROP
$IPT -A udp_inbound -p UDP -s 0/0 --destination-port 138 -j DROP
$IPT -A udp_inbound -p UDP -s 0/0 --source-port 67 --destination-port 68 -j ACCEPT
$IPT -A udp_inbound -m state --state NEW -p UDP -s 0/0 --destination-port 1194 -j ACCEPT #vpn
$IPT -A udp_inbound -p UDP -j RETURN

$IPT -A tcp_inbound -p TCP -s $INET_ADMIN --destination-port 2222 -j ACCEPT #ssh
$IPT -A tcp_inbound -p TCP -j RETURN

$IPT -A udp_outbound -p UDP -s 0/0 -j ACCEPT
$IPT -A tcp_outbound -p TCP -s 0/0 -j ACCEPT

###############################################################################
echo "Process INPUT chain ..."

$IPT -A INPUT -p ALL -i $LO_IFACE -j ACCEPT
#$IPT -A INPUT -p ALL -j bad_packets
$IPT -A INPUT -p ALL -i $LOCAL_IFACE -s $LOCAL_NET -j ACCEPT
$IPT -A INPUT -p ALL -i $LOCAL_IFACE -d $LOCAL_BCAST -j ACCEPT

$IPT -A INPUT -p ALL -i $WIFI_IFACE -s $WIFI_NET -j ACCEPT
$IPT -A INPUT -p ALL -i $WIFI_IFACE -d $WIFI_BCAST -j ACCEPT

$IPT -A INPUT -p ALL -i $VIDEO_IFACE -s $VIDEO_NET -j ACCEPT
$IPT -A INPUT -p ALL -i $VIDEO_IFACE -d $VIDEO_BCAST -j ACCEPT

$IPT -A INPUT -p ALL -i $VOIP_IFACE -s $VOIP_NET -j ACCEPT
$IPT -A INPUT -p ALL -i $VOIP_IFACE -d $VOIP_BCAST -j ACCEPT

$IPT -A INPUT -p ALL -i $VPN_IFACE -j ACCEPT
$IPT -A INPUT -p ALL -i $EVOIP_IFACE -j ACCEPT

$IPT -A INPUT -p ALL -i $INET_IFACE -m state --state ESTABLISHED,RELATED -j ACCEPT

$IPT -A INPUT -p TCP -i $INET_IFACE -j tcp_inbound
$IPT -A INPUT -p UDP -i $INET_IFACE -j udp_inbound
$IPT -A INPUT -p ICMP -i $INET_IFACE -j icmp_packets

#$IPT -A INPUT -m pkttype --pkt-type broadcast -j DROP
#$IPT -A INPUT -j LOG --log-prefix "fp=INPUT:99 a=DROP "

###############################################################################
echo "Process FORWARD chain ..."

#$IPT -A FORWARD -p ALL -j bad_packets
$IPT -A FORWARD -p tcp -i $LOCAL_IFACE -j tcp_outbound
$IPT -A FORWARD -p udp -i $LOCAL_IFACE -j udp_outbound
$IPT -A FORWARD -p ALL -i $LOCAL_IFACE -j ACCEPT

#forward VIDEO vlan1015 to internet but not to the local network!
###$IPT -A FORWARD -p ALL -i $VIDEO_IFACE -d $LOCAL_NET -j LOG --log-prefix "fp=FORWARD:99 a=DROP "
###$IPT -A FORWARD -p ALL -i $VIDEO_IFACE -d $LOCAL_NET -j DROP
$IPT -A FORWARD -p ALL -i $VIDEO_IFACE -d $LOCAL_NET -j ACCEPT
$IPT -A FORWARD -p ALL -i $VIDEO_IFACE -s $VIDEO_NET -j ACCEPT

#forward VOIP vlan1016 to internet but not to the local network!
$IPT -A FORWARD -p ALL -i $VOIP_IFACE -d $LOCAL_NET -j LOG --log-prefix "fp=FORWARD:99 a=DROP "
$IPT -A FORWARD -p ALL -i $VOIP_IFACE -d $LOCAL_NET -j DROP
$IPT -A FORWARD -p ALL -i $VOIP_IFACE -s $VOIP_NET -j ACCEPT

#forward WIFI vlan1017 to internet but not to the local network!
$IPT -A FORWARD -p ALL -i $WIFI_IFACE -d $LOCAL_NET -j LOG --log-prefix "fp=FORWARD:99 a=DROP "
$IPT -A FORWARD -p ALL -i $WIFI_IFACE -d $LOCAL_NET -j DROP
#wifi to DVR allowed:
$IPT -A FORWARD -p ALL -i $WIFI_IFACE -d 192.168.15.2 -j ACCEPT
$IPT -A FORWARD -p ALL -i $WIFI_IFACE -d 192.168.15.1 -j ACCEPT
$IPT -A FORWARD -p ALL -i $WIFI_IFACE -d $VIDEO_NET -j DROP
$IPT -A FORWARD -p ALL -i $WIFI_IFACE -d $VOIP_NET -j LOG --log-prefix "fp=FORWARD:99 a=DROP "
$IPT -A FORWARD -p ALL -i $WIFI_IFACE -d $VOIP_NET -j DROP
$IPT -A FORWARD -p ALL -i $WIFI_IFACE -s $WIFI_NET -j ACCEPT

#forward VPN
$IPT -A FORWARD -p ALL -i $VPN_IFACE -s $VPN_NET -j ACCEPT
#$IPT -A FORWARD -i $VPN_IFACE -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -i $EVOIP_IFACE -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -i $INET_IFACE -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -j LOG --log-prefix "fp=FORWARD:99 a=DROP "

###############################################################################
echo "Process OUTPUT chain ..."

$IPT -A OUTPUT -m state -p icmp --state INVALID -j DROP
$IPT -A OUTPUT -p ALL -s $LO_IP -j ACCEPT
$IPT -A OUTPUT -p ALL -o $LO_IFACE -j ACCEPT

$IPT -A OUTPUT -p ALL -s $LOCAL_IP -j ACCEPT
$IPT -A OUTPUT -p ALL -o $LOCAL_IFACE -j ACCEPT

$IPT -A OUTPUT -p ALL -s $VIDEO_IP -j ACCEPT
$IPT -A OUTPUT -p ALL -o $VIDEO_IFACE -j ACCEPT

$IPT -A OUTPUT -p ALL -s $WIFI_IP -j ACCEPT
$IPT -A OUTPUT -p ALL -o $WIFI_IFACE -j ACCEPT

$IPT -A OUTPUT -p ALL -s $VOIP_IP -j ACCEPT
$IPT -A OUTPUT -p ALL -o $VOIP_IFACE -j ACCEPT

$IPT -A OUTPUT -p ALL -o $VPN_IFACE -j ACCEPT

$IPT -A OUTPUT -p ALL -o $EVOIP_IFACE -j ACCEPT
$IPT -A OUTPUT -p ALL -o $INET_IFACE -j ACCEPT
$IPT -A OUTPUT -j LOG --log-prefix "fp=OUTPUT:99 a=DROP "

###############################################################################
echo "Load rules for nat table ..."

$IPT -t nat -A POSTROUTING -o $INET_IFACE -j MASQUERADE
$IPT -t nat -A POSTROUTING -o $EVOIP_IFACE -j MASQUERADE
$IPT -t nat -A POSTROUTING -s $VPN_NET -o $INET_IFACE -j MASQUERADE #vpn

###
echo "Loading extra rules ..."

#VOIP
$IPT -I FORWARD -p udp -i $EVOIP_IFACE -d 192.168.16.2 --dport 5060 -j ACCEPT
$IPT -t nat -I PREROUTING -p udp -i $EVOIP_IFACE --dport 5060 -j DNAT --to 192.168.16.2:5060
$IPT -I FORWARD -p udp -i $EVOIP_IFACE -d 192.168.16.2 --dport 10000:20000 -j ACCEPT
$IPT -t nat -I PREROUTING -p udp -i $EVOIP_IFACE --dport 10000:20000 -j DNAT --to 192.168.16.2:10000-20000

#NVR
$IPT -I FORWARD -p tcp -i $INET_IFACE -s 0/0 -d 192.168.15.251 --dport 8001 -j ACCEPT
$IPT -t nat -I PREROUTING -p tcp -i $INET_IFACE --dport 8001 -j DNAT --to 192.168.15.251:8001
$IPT -t nat -I PREROUTING -p tcp -i $WIFI_IFACE -s $WIFI_NET -d $INET_IP --dport 8001 -j DNAT --to 192.168.15.251:8001
$IPT -t nat -I POSTROUTING -p tcp -o $WIFI_IFACE -s $VIDEO_NET -d 192.168.15.251 --dport 8001 -j SNAT --to $INET_IP
#substream
$IPT -I FORWARD -p tcp -i $INET_IFACE -s 0/0 -d 192.168.15.251 --dport 554 -j ACCEPT
$IPT -t nat -I PREROUTING -p tcp -i $INET_IFACE --dport 554 -j DNAT --to 192.168.15.251:554
$IPT -t nat -I PREROUTING -p tcp -i $WIFI_IFACE -s $WIFI_NET -d $INET_IP --dport 554 -j DNAT --to 192.168.15.250:554
$IPT -t nat -I POSTROUTING -p tcp -o $WIFI_IFACE -s $VIDEO_NET -d 192.168.15.251 --dport 554 -j SNAT --to $INET_IP
