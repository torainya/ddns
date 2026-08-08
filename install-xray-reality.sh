#!/bin/bash

set -e

echo "=================================="
echo " Xray Reality + Clash Deploy"
echo "=================================="


# ========= 参数 =========

PORT=${PORT:-443}

SNI="www.cloudflare.com"

XRAY_VERSION="v25.12.8"

XRAY_DIR="/usr/local/etc/xray"

CLASH_FILE="/root/clash-node.yaml"


UUID=$(cat /proc/sys/kernel/random/uuid)


get_ip(){

curl -4 -s https://ipv4.icanhazip.com \
|| curl -4 -s https://api.ipify.org \
|| echo "YOUR_IP"

}


SERVER_IP=$(get_ip)



echo "[1/7] Install dependency"


apt update -y

apt install -y \
curl \
unzip \
openssl \
ca-certificates


echo "[2/7] Install Xray"


ARCH=$(uname -m)


case $ARCH in

x86_64)
XRAY_FILE="Xray-linux-64.zip"
;;

aarch64)
XRAY_FILE="Xray-linux-arm64-v8a.zip"
;;

armv7l)
XRAY_FILE="Xray-linux-arm32-v7a.zip"
;;

*)
echo "Unsupported architecture"
exit 1
;;

esac



echo "Architecture: $ARCH"



cd /tmp


rm -rf xray.zip xray geoip.dat geosite.dat



wget -q \
"https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/${XRAY_FILE}" \
-O xray.zip



unzip -o xray.zip



install -m 755 xray /usr/local/bin/xray



echo "Xray version:"

/usr/local/bin/xray version



echo "[3/7] Generate Reality key"



KEY=$(/usr/local/bin/xray x25519)

PRIVATE_KEY=$(echo "$KEY" | grep "Private key" | awk '{print $3}')

PUBLIC_KEY=$(echo "$KEY" | grep "Password" | awk '{print $2}')

if [ -z "$PRIVATE_KEY" ] || [ -z "$PUBLIC_KEY" ]; then
    echo "Reality key generate failed"
    echo "$KEY"
    exit 1
fi


if [ -z "$PRIVATE_KEY" ]; then

echo "Reality key generate failed"

exit 1

fi



SHORT_ID=$(openssl rand -hex 8)



echo "[4/7] Create config"



mkdir -p $XRAY_DIR



cat > $XRAY_DIR/config.json <<EOF

{
"log":{
"loglevel":"none"
},

"inbounds":[
{
"port":$PORT,
"protocol":"vless",

"settings":{
"clients":[
{
"id":"$UUID",
"flow":"xtls-rprx-vision"
}
],
"decryption":"none"
},

"streamSettings":{
"network":"tcp",
"security":"reality",

"realitySettings":{
"show":false,
"dest":"$SNI:443",
"xver":0,

"serverNames":[
"$SNI"
],

"privateKey":"$PRIVATE_KEY",

"shortIds":[
"$SHORT_ID"
]
}
}
}
],

"outbounds":[
{
"protocol":"freedom"
}
]

}

EOF



echo "[5/7] Create systemd"



cat >/etc/systemd/system/xray.service <<EOF

[Unit]
Description=Xray Reality
After=network.target


[Service]

Type=simple

ExecStart=/usr/local/bin/xray run -config $XRAY_DIR/config.json

Restart=always

RestartSec=5


[Install]

WantedBy=multi-user.target

EOF



echo "[6/7] Start Xray"



systemctl daemon-reload

systemctl enable xray

systemctl restart xray



sleep 2



systemctl status xray --no-pager



echo "[7/7] Generate Clash"



cat > $CLASH_FILE <<EOF

- name: "Reality-$SERVER_IP"

  type: vless

  server: $SERVER_IP

  port: $PORT

  uuid: $UUID

  network: tcp

  udp: true

  tls: true

  flow: xtls-rprx-vision

  servername: $SNI

  reality-opts:

    public-key: $PUBLIC_KEY

    short-id: $SHORT_ID

  client-fingerprint: chrome

EOF



cat $CLASH_FILE



echo ""

echo "=================================="

echo "Done"

echo "Saved: $CLASH_FILE"

echo "=================================="
