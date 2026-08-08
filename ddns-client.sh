#!/bin/bash


set -e



BASE_DIR="/root/ddns"

CONFIG="$BASE_DIR/config"


WORKER_URL="https://ddns.torainya.com"



if [ ! -f "$CONFIG" ]; then

echo "Config missing"

exit 1

fi



source "$CONFIG"



echo "=============================="

echo "DDNS Sync"

echo "=============================="



echo "Domain:"
echo "$DOMAIN"



################################
# 获取IPv4
################################


IPV4=$(curl -4 -s https://api.ipify.org || true)



################################
# 获取IPv6
################################


IPV6=$(curl -6 -s https://api64.ipify.org || true)



echo ""

echo "IPv4:"
echo "$IPV4"


echo ""

echo "IPv6:"
echo "$IPV6"



################################
# 构造JSON
################################


JSON=$(cat <<EOF
{
"domain":"$DOMAIN",
"ipv4":"$IPV4",
"ipv6":"$IPV6"
}
EOF
)



################################
# 请求Worker
################################


RESULT=$(curl -s \
-X POST "$WORKER_URL" \
-H "Content-Type: application/json" \
-H "X-KEY:$GLOBE_KEY" \
-d "$JSON"
)



echo ""

echo "Result:"

echo "$RESULT"



echo ""

echo "完成"
