#!/bin/bash

set -e


#################################
# DDNS Client
# IPv4 + IPv6 Cloudflare Worker
# Auto Sync Every 3 Hours
#################################


BASE_DIR="/root/ddns"

CONFIG_FILE="$BASE_DIR/config"

SCRIPT_FILE="$BASE_DIR/ddns-client.sh"

WORKER_URL="https://ddns.torainya.com"

CRON_TIME="0 */3 * * *"



mkdir -p $BASE_DIR



#################################
# 保存自身
#################################

if [ "$0" != "$SCRIPT_FILE" ]; then

    cp "$0" "$SCRIPT_FILE" 2>/dev/null || true

    chmod +x "$SCRIPT_FILE"

fi



#################################
# 第一次配置
#################################

if [ ! -f "$CONFIG_FILE" ]; then


echo "=============================="
echo " DDNS首次配置"
echo "=============================="


read -p "请输入域名，例如 jp.torainya.com: " DOMAIN


read -p "请输入GLOBE_KEY: " GLOBE_KEY



cat > $CONFIG_FILE <<EOF

DOMAIN="$DOMAIN"

GLOBE_KEY="$GLOBE_KEY"

EOF


chmod 600 $CONFIG_FILE


echo "配置保存完成"


fi



#################################
# 读取配置
#################################

source $CONFIG_FILE



#################################
# 获取IP
#################################

echo "=============================="
echo "开始检测IP"
echo "=============================="


IPV4=$(curl -4 -s https://api.ipify.org || true)


IPV6=$(curl -6 -s https://api64.ipify.org || true)



echo "IPv4:"
echo "$IPV4"


echo "IPv6:"
echo "$IPV6"



#################################
# 更新DDNS
#################################


echo "同步 Cloudflare..."



DATA=$(cat <<EOF
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
-d "$DATA"
)



echo "$RESULT"



#################################
# 安装cron
#################################


install_cron(){


if command -v crontab >/dev/null 2>&1; then

    return

fi



echo "安装cron..."



if command -v apt >/dev/null 2>&1; then


    apt update -y

    apt install -y cron

    systemctl enable cron

    systemctl start cron



elif command -v yum >/dev/null 2>&1; then


    yum install -y cronie

    systemctl enable crond

    systemctl start crond



elif command -v apk >/dev/null 2>&1; then


    apk add --no-cache dcron

    rc-update add dcron

    rc-service dcron start


else

    echo "无法自动安装cron"

    return

fi


}



install_cron



#################################
# 添加定时任务
#################################


CRON_JOB="$CRON_TIME $SCRIPT_FILE >/dev/null 2>&1"



if crontab -l 2>/dev/null | grep -q "$SCRIPT_FILE"; then


echo "DDNS定时任务已存在"


else


(
crontab -l 2>/dev/null
echo "$CRON_JOB"
) | crontab -


echo "已添加3小时同步"


fi



echo "=============================="
echo " DDNS同步完成"
echo "=============================="
