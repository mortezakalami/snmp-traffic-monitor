#!/usr/bin/env bash

#Your host or router gateway
HOST="192.168.1.1"
COMMUNITY="YOUR_COMMUNITY"
IFINDEX="210000"

RX_OID="1.3.6.1.2.1.2.2.1.10.$IFINDEX"
TX_OID="1.3.6.1.2.1.2.2.1.16.$IFINDEX"

MAX_COUNTER=4294967296


get_counter() {
    snmpget -v2c -c "$COMMUNITY" -Oqv "$HOST" "$1" 2>/dev/null
}


format_bytes() {
    awk "BEGIN { printf \"%.2f MB\", $1 / 1000000 }"
}


format_rate() {
    awk "BEGIN { printf \"%.2f MB/s\", $1 / 1000000 }"
}


format_time() {
    local sec=$1

    printf "%02dd %02dh %02dm %02ds" \
        $((sec / 86400)) \
        $((sec / 3600 % 24)) \
        $((sec / 60 % 60)) \
        $((sec % 60))
}


echo "Reading router counters..."

prev_rx=$(get_counter "$RX_OID")
prev_tx=$(get_counter "$TX_OID")

if ! [[ "$prev_rx" =~ ^[0-9]+$ && "$prev_tx" =~ ^[0-9]+$ ]]; then
    echo "Could not read SNMP counters."
    echo "Check the router IP, community and interface index."
    exit 1
fi


total_rx=0
total_tx=0

start=$(date +%s)
last_time=$start


while true; do

    sleep 1

    rx=$(get_counter "$RX_OID")
    tx=$(get_counter "$TX_OID")

    now=$(date +%s)

    # SNMP didn't respond
    if ! [[ "$rx" =~ ^[0-9]+$ && "$tx" =~ ^[0-9]+$ ]]; then
        clear
        echo "================================"
        echo "       SNMP TRAFFIC MONITOR"
        echo "================================"
        echo
        echo "Router    : $HOST"
        echo "Interface : pppoe1"
        echo
        echo "SNMP connection error..."
        echo "Waiting for router..."
        continue
    fi


    elapsed=$((now - last_time))

    (( elapsed < 1 )) && elapsed=1


    # RX
    if (( rx >= prev_rx )); then
        rx_delta=$((rx - prev_rx))
    else
        rx_delta=$((MAX_COUNTER - prev_rx + rx))

        # probably interface/router reset
        (( rx_delta > 1000000000 )) && rx_delta=0
    fi


    # TX
    if (( tx >= prev_tx )); then
        tx_delta=$((tx - prev_tx))
    else
        tx_delta=$((MAX_COUNTER - prev_tx + tx))

        (( tx_delta > 1000000000 )) && tx_delta=0
    fi


    total_rx=$((total_rx + rx_delta))
    total_tx=$((total_tx + tx_delta))

    total=$((total_rx + total_tx))


    rx_rate=$(awk -v b="$rx_delta" -v t="$elapsed" \
        'BEGIN { printf "%.2f", b / t }')

    tx_rate=$(awk -v b="$tx_delta" -v t="$elapsed" \
        'BEGIN { printf "%.2f", b / t }')


    session=$((now - start))


    clear

    echo "================================"
    echo "       SNMP TRAFFIC MONITOR"
    echo "================================"
    echo
    echo "Router    : $HOST"
    echo "Interface : pppoe1"
    echo "Time      : $(date '+%H:%M:%S')"
    echo "Session   : $(format_time "$session")"
    echo
    echo "------------- SPEED ------------"
    echo "Download  : $(format_rate "$rx_rate")"
    echo "Upload    : $(format_rate "$tx_rate")"
    echo
    echo "------------- TOTAL ------------"
    echo "Download  : $(format_bytes "$total_rx")"
    echo "Upload    : $(format_bytes "$total_tx")"
    echo "Total     : $(format_bytes "$total")"
    echo
    echo "----------- COUNTERS -----------"
    echo "RX        : $rx"
    echo "TX        : $tx"
    echo "================================"


    prev_rx=$rx
    prev_tx=$tx
    last_time=$now

done
