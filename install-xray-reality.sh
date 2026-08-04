apt update -y
apt install -y curl unzip openssl ca-certificates
wget -O install-xray-reality.sh https://raw.githubusercontent.com/torainya/xray-reality-install-clash-yaml/main/install-xray-reality.sh
chmod +x install-xray-reality.sh
nohup bash install-xray-reality.sh > install.log 2>&1 &

#!/bin/bash

set -e

echo "=================================="
echo " Xray Reality + Clash Auto Deploy "
echo "=================================="


# ===== 用户参数 =====

PORT_IN=${PORT_IN:-443}
PORT_OUT=${PORT_OUT:-44645}

SNI="www.cloudflare.com"

SERVER_IP=$(curl -s ipv4.icanhazip.com || echo "YOUR_SERVER_IP")


UUID=$(cat /proc/sys/kernel/random/uuid)


XRAY_DIR="/usr/local/etc/xray"
CLASH_FILE="/root/clash-node.yaml"


echo "[1/7] Install dependency"

apt update -y
apt install -y curl unzip openssl ca-certificates


echo "[2/7] Install Xray"


if [ ! -f /usr/local/bin/xray ]; then

cd /tmp

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
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Detected architecture: $ARCH"
echo "Downloading: $XRAY_FILE"

curl -L \
https://github.com/XTLS/Xray-core/releases/latest/download/$XRAY_FILE \
-o xray.zip


unzip -o xray.zip

install -m 755 xray /usr/local/bin/xray

fi



echo "[3/7] Generate Reality key"


KEY=$(xray x25519)

PRIVATE_KEY=$(echo "$KEY" | grep PrivateKey | awk '{print $2}')

PUBLIC_KEY=$(echo "$KEY" | grep Password | awk '{print $3}')

SHORT_ID=$(openssl rand -hex 8)



echo "[4/7] Create Xray config"


mkdir -p $XRAY_DIR


cat > $XRAY_DIR/config.json <<EOF
{
"log":{
 "loglevel":"none"
},

"inbounds":[
{
 "port":$PORT_IN,
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
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF



echo "[6/7] Start Xray"


systemctl daemon-reload

systemctl enable xray

systemctl restart xray



 echo "[7/7] Create Clash YAML Node "

echo ""
echo "=================================="
echo "生成 Clash YAML 节点"
echo "=================================="


cat > $CLASH_FILE <<EOF
- name: "Reality-$SERVER_IP"
  type: vless
  server: $SERVER_IP
  port: $PORT_OUT
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
echo "节点已保存:"
echo "$CLASH_FILE"
echo "=================================="
