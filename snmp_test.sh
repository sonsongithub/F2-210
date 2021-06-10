#!/bin/sh

# expects the following env vars
# METRIC_PREFIX - At least the hostname to record these stats under in graphite - collectd.someserver
# SNMP_HOST - the host to pull snmp stats from
# CARBON_HOST - The carbon host to send the stats
# CARBON_PORT - The carbon port to send the stats

NOW="$(date +%s)"

snmpId() {
    echo "$1" | awk '{print $1}'
}

snmpVal() {
    echo "$1" | awk '{print $3}' | tr -d '"'
}

sendStat() {
    echo "$METRIC_PREFIX.$1 $2 at $NOW" #| nc "$CARBON_HOST" "$CARBON_PORT"
}

SNMP_HOST=$1

echo $SNMP_HOST

IFACE_NAMES="$(snmpwalk -OQtn -v 2c -c "public" "$SNMP_HOST" "1.3.6.1.2.1.2.2.1.2")"
findName() {
    id="$(snmpId "$1" | rev | cut -d'.' -f1 | rev)"
    echo "$IFACE_NAMES" | grep "$id =" | awk '{print $3}' | tr -d '"'
}


# Memory info
    echo "A"
snmpwalk -OQtn -v 2c -c "public" "$SNMP_HOST" "1.3.6.1.4.1.2021.4" | while read line; do
    field=""
    id="$(snmpId "$line")"
    val="$(snmpVal "$line")"
    echo $line
    case "$id" in
        ".1.3.6.1.4.1.2021.4.5.0") field="memory.memory.total";;
        ".1.3.6.1.4.1.2021.4.6.0") field="memory.memory.free";;
        ".1.3.6.1.4.1.2021.4.13.0") field="memory.memory.shared";;
        ".1.3.6.1.4.1.2021.4.14.0") field="memory.memory.buffered";;
        ".1.3.6.1.4.1.2021.4.15.0") field="memory.memory.cached";;
    esac

    if [ "$field" != "" ]; then
        echo $id
        sendStat "$field" "$val"
    fi
    echo "???"
done

    echo "B"
# System info
snmpwalk -OQtn -v 2c -c "public" "$SNMP_HOST" "1.3.6.1.2.1.25.1" | while read line; do
    field=""
    id="$(snmpId "$line")"
    val="$(snmpVal "$line")"

    case "$id" in
        ".1.3.6.1.2.1.25.1.1.0") field="uptime.uptime"; val="$(expr "$val" / 100)";;
        ".1.3.6.1.2.1.25.1.5.0") field="users.users";;
        ".1.3.6.1.2.1.25.1.6.0") field="processes.processes";;
    esac

    if [ "$field" != "" ]; then
        sendStat "$field" "$val"
    fi
done

# load
snmpwalk -OQtn -v 2c -c "public" "$SNMP_HOST" "1.3.6.1.4.1.2021.10.1.3" | while read line; do
    field=""
    id="$(snmpId "$line")"
    val="$(snmpVal "$line")"

    case "$id" in
        ".1.3.6.1.4.1.2021.10.1.3.1") field="load.load.shortterm";;
        ".1.3.6.1.4.1.2021.10.1.3.2") field="load.load.midterm";;
        ".1.3.6.1.4.1.2021.10.1.3.3") field="load.load.longterm";;
    esac

    if [ "$field" != "" ]; then
        sendStat "$field" "$val"
    fi
done

# cpu info
snmpwalk -OQtn -v 2c -c "public" "$SNMP_HOST" "1.3.6.1.4.1.2021.11" | while read line; do
    field=""
    id="$(snmpId "$line")"
    val="$(snmpVal "$line")"

    case "$id" in
        ".1.3.6.1.4.1.2021.11.9.0") field="cpu.0.percent.user";;
        ".1.3.6.1.4.1.2021.11.10.0") field="cpu.0.percent.system";;
        ".1.3.6.1.4.1.2021.11.11.0") field="cpu.0.percent.idle";;
    esac

    if [ "$field" != "" ]; then
        sendStat "$field" "$val"
    fi
done

# 32 bit interface stats
snmpwalk -OQtn -v 2c -c "public" "$SNMP_HOST" "1.3.6.1.2.1.2.2.1" | while read line; do
    field=""
    id="$(snmpId "$line")"
    val="$(snmpVal "$line")"
    name="$(findName "$line")"

    case "$id" in
        ".1.3.6.1.2.1.2.2.1.13."*) field="interface.$name.if_discards.rx";;
        ".1.3.6.1.2.1.2.2.1.14."*) field="interface.$name.if_errors.rx";;
        ".1.3.6.1.2.1.2.2.1.15."*) field="interface.$name.if_unknown_protocols.rx";;
        ".1.3.6.1.2.1.2.2.1.19."*) field="interface.$name.if_discards.tx";;
        ".1.3.6.1.2.1.2.2.1.20."*) field="interface.$name.if_errors.tx";;
        ".1.3.6.1.2.1.2.2.1.21."*) field="interface.$name.if_queue.tx";;
    esac

    if [ "$field" != "" ]; then
        sendStat "$field" "$val"
    fi
done

# 64 bit interface stats
snmpwalk -OQtn -v 2c -c "public" "$SNMP_HOST" "1.3.6.1.2.1.31.1.1.1" | while read line; do
    field=""
    id="$(snmpId "$line")"
    val="$(snmpVal "$line")"
    name="$(findName "$line")"

    case "$id" in
        ".1.3.6.1.2.1.31.1.1.1.6."*) field="interface.$name.if_octets.rx";;
        ".1.3.6.1.2.1.31.1.1.1.7."*) field="interface.$name.if_unicast_packets.rx";;
        ".1.3.6.1.2.1.31.1.1.1.8."*) field="interface.$name.if_multicast_packets.rx";;
        ".1.3.6.1.2.1.31.1.1.1.9."*) field="interface.$name.if_broadcast_packets.rx";;
        ".1.3.6.1.2.1.31.1.1.1.10."*) field="interface.$name.if_octets.tx";;
        ".1.3.6.1.2.1.31.1.1.1.11."*) field="interface.$name.if_unicast_packets.tx";;
        ".1.3.6.1.2.1.31.1.1.1.12."*) field="interface.$name.if_multicast_packets.tx";;
        ".1.3.6.1.2.1.31.1.1.1.13."*) field="interface.$name.if_broadcast_packets.tx";;
    esac

    if [ "$field" != "" ]; then
        echo $id
        sendStat "$field" "$val"
    fi
done