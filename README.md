# SNMP Traffic Monitor

A simple Bash script for checking the download and upload traffic of a router using SNMP.

I made this mainly to monitor my router's traffic in real time without using a graphical application.

## What it does

* Shows current download speed
* Shows current upload speed
* Shows total downloaded/uploaded data
* Reads traffic counters using SNMP
* Handles temporary SNMP connection errors
* Handles Counter32 rollover

## Requirements

You need:

* Linux
* Bash
* `snmpget`

Install SNMP tools on Debian/Ubuntu:

```bash
sudo apt install snmp
```

## Setup

Open `traffic_monitor.sh` and change these values:

```bash
HOST="192.168.1.1"
COMMUNITY="YOUR_COMMUNITY"
IFINDEX="YOUR_INTERFACE_INDEX"
```

You need to enable SNMP on your router and find the interface index you want to monitor.

## Run

Make the script executable:

```bash
chmod +x traffic_monitor.sh
```

Then run:

```bash
./traffic_monitor.sh
```

The script updates the information every second.

Press `Ctrl+C` to stop it.

## Example

```text
================================
       SNMP TRAFFIC MONITOR
================================

Router    : 192.168.1.1
Interface : pppoe1
Time      : 23:14:32
Session   : 00d 00h 04m 21s

------------- SPEED ------------
Download  : 1.24 MB/s
Upload    : 0.08 MB/s

------------- TOTAL ------------
Download  : 324.51 MB
Upload    : 18.42 MB
Total     : 342.93 MB
```

## How it works

The script gets the RX and TX byte counters from the router using SNMP.

It compares the current counter with the previous one and uses the difference to calculate the traffic rate.

```text
current counter - previous counter
                ↓
          bytes transferred
                ↓
          bytes / second
                ↓
              MB/s
```

## Note

The interface index and SNMP community are different for each router, so the values in the script may need to be changed.

This is a small personal project and can be improved with things like logging, graphs and longer-term traffic statistics.
