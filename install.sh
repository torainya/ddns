#!/bin/bash

set -e


echo "================================"
echo " Cloudflare DDNS Installer"
echo "================================"


BASE_DIR="/root/ddns"

CLIENT="$BASE_DIR/ddns-client.sh"

CONFIG="$BASE_DIR/config"


mkdir -p $BASE_DIR



################################
# 下载客户端
################################


echo "[1/4] Download client"


curl -fsSL \
https://raw.githubusercontent.com/torainya/xray/main/ddns-client.sh \
-o $CLIENT


chmod +x $CLIENT



################################
# 初始化配置
################################


if [ ! -f "$CONFIG" ]; then


echo ""
echo "首次配置"
echo ""


read -p "请输入域名(example.torainya.com): " DOMAIN


read -p "请输入GLOBE_KEY: " GLOBE_KEY



cat > $CONFIG <<EOF
DOMAIN="$DOMAIN"
GLOBE_KEY="$GLOBE_KEY"
EOF


chmod 600 $CONFIG


fi



################################
# 安装cron
################################


echo "[2/4] Install cron"


if ! command -v crontab >/dev/null 2>&1
then


if command -v apt >/dev/null 2>&1
then

apt update -y
apt install -y cron

systemctl enable cron
systemctl start cron


elif command -v yum >/dev/null 2>&1
then

yum install -y cronie

systemctl enable crond
systemctl start crond


else

echo "无法自动安装cron"
exit 1

fi


fi



################################
# 添加定时任务
################################


echo "[3/4] Setup cron"


CRON="0 */3 * * * $CLIENT >/dev/null 2>&1"



(crontab -l 2>/dev/null | grep -v "$CLIENT" || true
echo "$CRON"
) | crontab -



################################
# 立即执行
################################


echo "[4/4] First sync"


bash $CLIENT


echo ""
echo "================================"
echo " DDNS安装完成"
echo " 每3小时自动同步"
echo "================================"
