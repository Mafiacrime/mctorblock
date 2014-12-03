#!/bin/bash
#For MafiaCrime.org

#Create TOR Table
iptables -N TOR

#Create Input Set
iptables -I INPUT 1 -j TOR

readonly CHAIN_NAME="TOR"
readonly TMP_TOR_LIST="/tmp/temp_tor_list"
readonly IP_ADDRESS=46.105.99.189

if [ "$1" == "" ]; then
    echo "usage ./torblock.sh 80 <--Specify the ports you want to block. :-)"
    echo "$0 port [port [port [...]]]"
    echo
    echo "First, you must manually create the iptable:"
    echo "  iptables -N $CHAIN_NAME"
    echo "  iptables -I INPUT 1 -j $CHAIN_NAME"
    exit 1
fi


# Create tor chain if it doesn't exist. This is basically a grouping of
# filters within iptables.
if ! iptables -L "$CHAIN_NAME" -n >/dev/null 2>&1 ; then
    iptables -N "$CHAIN_NAME" >/dev/null 2>&1
fi

# Download the exit list from the tor project, build the temp file. Also
# filter out any commented (#) lines.
rm -f $TMP_TOR_LIST
touch $TMP_TOR_LIST

for PORT in "$@"
do
    wget -q -O - "https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=$IP_ADDRESS&port=$PORT" -U NoSuchBrowser/1.0 >> $TMP_TOR_LIST
    echo >> $TMP_TOR_LIST
done

sed -i 's|^#.*$||g' $TMP_TOR_LIST

# Block the contents of the list in iptables
iptables -F $CHAIN_NAME

for IP in $(cat $TMP_TOR_LIST | uniq | sort)
do
    iptables -A $CHAIN_NAME -s $IP -j DROP
done

iptables-save
