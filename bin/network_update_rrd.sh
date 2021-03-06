#!/bin/bash

RHIZO_DIR="/var/rhizomatica/rrd"

channels=`echo "show network" | nc -q1 localhost 4242 | awk 'BEGIN {tch=0;sdcch=0} /TCH\/F/ {tch=$2}; /SDCCH8/ {sdcch=$2} ; {sub(/%/,"",tch); sub(/%/,"",sdcch)} END {print tch":"sdcch}'`
rrdtool update $RHIZO_DIR/bsc_channels.rrd N:$channels

broken=`echo "show lchan" | nc -q1 localhost 4242 | grep BROKEN | wc -l`
rrdtool update $RHIZO_DIR/broken.rrd N:$broken

calls=`fs_cli --timeout=5000 --connect-timeout=5000 -x 'show calls count' | grep total | awk '{print $1}'`
rrdtool update $RHIZO_DIR/fs_calls.rrd N:$calls

stats=`echo "show statistics" | nc -q1 localhost 4242 | awk 'BEGIN {cr=0;crn=0;lur=0;lurr=0;sms_mo=0;sms_mt=0;moc=0;moca=0;mtc=0;mtca=0}; /Channel Requests/ {cr=$4;crn=$6} /Location Update Response/ {lur=$4;lurr=$6} /SMS MO/ {sms_mo=$4}; /SMS MT/ {sms_mt=$4} /MO Calls/ {moc=$4;moca=$6}; /MT Calls/ {mtc=$4;mtca=$6} END {print cr":"crn":"lur":"lurr":"sms_mo":"sms_mt":"moc":"moca":"mtc":"mtca}' `
rrdtool update $RHIZO_DIR/stats.rrd N:$stats

online_reg_subs=`echo "select count(*) from Subscriber where length(extension) = 11 and lac>0;" | sqlite3 -init <(echo .timeout 1000) /var/lib/osmocom/hlr.sqlite3`
online_noreg_subs=`echo "select count(*) from Subscriber where length(extension) = 5 and lac>0;" | sqlite3 -init <(echo .timeout 1000) /var/lib/osmocom/hlr.sqlite3`
rrdtool update $RHIZO_DIR/hlr.rrd N:$online_reg_subs:$online_noreg_subs

$RHIZO_DIR/../bin/network_graph_rrd.sh > /dev/null
