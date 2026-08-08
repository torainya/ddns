#!/bin/bash


set -e


BASE_DIR="/root/ddns"

CONFIG="$BASE_DIR/config"


WORKER_URL="https://ddns.torainya.com"



if [ ! -f "$CONFIG" ]
then

echo "配置不存在"

exit 1

fi



source $CONFIG



echo "=============================="
echo "DDNS Sync"
echo "=============================="


IPV4=$(curl -4 -s https://api.ipify.org || true)


IPV6=$(curl -6 -s https://api64.ipify.org || true)



echo "Domain:"
echo $DOMAIN


echo "IPv4:"
echo $IPV4


echo "IPv6:"
echo $IPV6



JSON=$(cat <<EOF
{
"domain":"$DOMAIN",
"ipv4":"$IPV4",
"ipv6":"$IPV6"
}
EOF
)



RESULT=$(curl -s \
-X POST "$WORKER_URL" \
-H "Content-Type: application/json" \
-H "X-KEY:$GLOBE_KEY" \
-d "$JSON"
)



echo $RESULT


echo "=============================="
echo "完成"
echo "=============================="
