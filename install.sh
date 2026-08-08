#!/bin/bash

set -e


export DEBIAN_FRONTEND=noninteractive


BASE_DIR="/root/ddns"

CLIENT_FILE="$BASE_DIR/ddns-client.sh"

LOOP_FILE="$BASE_DIR/ddns-loop.sh"

CONFIG_FILE="$BASE_DIR/config"

SERVICE_FILE="/etc/systemd/system/ddns.service"


CLIENT_URL="https://raw.githubusercontent.com/torainya/xray/main/ddns-client.sh"


echo "======================================"
echo " Cloudflare DDNS Installer"
echo "======================================"


mkdir -p "$BASE_DIR"



#######################################
# 下载客户端
#######################################

echo "[1/5] Download client"


curl -fsSL "$CLIENT_URL" \
-o "$CLIENT_FILE"


chmod +x "$CLIENT_FILE"



#######################################
# 首次配置
#######################################

if [ ! -f "$CONFIG_FILE" ]; then


echo ""
echo "首次配置"
echo ""


read -p "请输入域名(例如 vn.torainya.com): " DOMAIN


read -p "请输入GLOBE_KEY: " GLOBE_KEY



cat > "$CONFIG_FILE" <<EOF
DOMAIN="$DOMAIN"
GLOBE_KEY="$GLOBE_KEY"
EOF


chmod 600 "$CONFIG_FILE"


echo "配置保存完成"


else

echo "检测到已有配置，跳过输入"


fi



#######################################
# 创建循环任务
#######################################

echo "[2/5] Create loop service"


cat > "$LOOP_FILE" <<'EOF'
#!/bin/bash


CLIENT="/root/ddns/ddns-client.sh"

LOG="/root/ddns/ddns.log"


while true
do


echo "================================" >> "$LOG"

echo "$(date) DDNS START" >> "$LOG"



if [ -f "$CLIENT" ]; then


    bash "$CLIENT" >> "$LOG" 2>&1


else


    echo "client missing" >> "$LOG"


fi



echo "$(date) sleep 3 hours" >> "$LOG"


sleep 10800


done

EOF


chmod +x "$LOOP_FILE"



#######################################
# 创建systemd
#######################################

echo "[3/5] Create systemd service"



cat > "$SERVICE_FILE" <<EOF

[Unit]
Description=Cloudflare DDNS Client

After=network-online.target

Wants=network-online.target



[Service]

Type=simple

ExecStart=$LOOP_FILE

Restart=always

RestartSec=10



[Install]

WantedBy=multi-user.target

EOF




#######################################
# 启动
#######################################

echo "[4/5] Enable service"



systemctl daemon-reload


systemctl enable ddns.service


systemctl restart ddns.service



#######################################
# 完成
#######################################

echo "[5/5] Finished"



echo ""

echo "======================================"

echo " DDNS安装完成"

echo ""

echo "配置文件:"
echo "$CONFIG_FILE"

echo ""

echo "日志:"
echo "/root/ddns/ddns.log"

echo ""

echo "查看状态:"
echo "systemctl status ddns"

echo "======================================"
