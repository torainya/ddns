#!/bin/bash

set -e


#####################################
# Cloudflare DDNS Installer
#####################################


export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a


BASE_DIR="/root/ddns"

CLIENT_FILE="$BASE_DIR/ddns-client.sh"

CONFIG_FILE="$BASE_DIR/config"


CLIENT_URL="https://raw.githubusercontent.com/torainya/xray/main/ddns-client.sh"


echo "======================================"
echo " Cloudflare DDNS Installer"
echo "======================================"


mkdir -p "$BASE_DIR"



#####################################
# 下载客户端
#####################################

echo "[1/5] Download DDNS client"


curl -fsSL "$CLIENT_URL" -o "$CLIENT_FILE"


chmod +x "$CLIENT_FILE"



#####################################
# 首次配置
#####################################

if [ ! -f "$CONFIG_FILE" ]; then


echo ""
echo "首次配置"
echo ""


read -p "请输入域名 (例如 vn.torainya.com): " DOMAIN


read -p "请输入 GLOBE_KEY: " GLOBE_KEY



cat > "$CONFIG_FILE" <<EOF
DOMAIN="$DOMAIN"
GLOBE_KEY="$GLOBE_KEY"
EOF


chmod 600 "$CONFIG_FILE"


echo "配置保存完成"


else


echo "检测到已有配置"


fi



#####################################
# 安装 cron
#####################################


echo "[2/5] Check cron"


if ! command -v crontab >/dev/null 2>&1
then


echo "未检测到 crontab，开始安装"



if command -v apt-get >/dev/null 2>&1
then


echo "Debian/Ubuntu detected"


apt-get update -y


apt-get install -y \
--no-install-recommends \
cron



elif command -v yum >/dev/null 2>&1
then


echo "CentOS detected"


yum install -y cronie



elif command -v apk >/dev/null 2>&1
then


echo "Alpine detected"


apk add --no-cache dcron



else


echo "不支持的系统"

exit 1


fi


fi



#####################################
# 启动 cron
#####################################


echo "[3/5] Start cron"



if command -v systemctl >/dev/null 2>&1
then

systemctl enable cron 2>/dev/null || \
systemctl enable crond 2>/dev/null || true


systemctl start cron 2>/dev/null || \
systemctl start crond 2>/dev/null || true



elif command -v service >/dev/null 2>&1
then


service cron start 2>/dev/null || true


fi




#####################################
# 添加定时任务
#####################################


echo "[4/5] Setup cron"



CRON_JOB="0 */3 * * * $CLIENT_FILE >/dev/null 2>&1"



(
crontab -l 2>/dev/null | grep -v "$CLIENT_FILE" || true

echo "$CRON_JOB"

) | crontab -



echo "已添加:"
echo "$CRON_JOB"



#####################################
# 第一次同步
#####################################


echo "[5/5] First sync"



bash "$CLIENT_FILE"



echo ""
echo "======================================"
echo " DDNS安装完成"
echo " 每3小时自动同步"
echo " 配置文件:"
echo "$CONFIG_FILE"
echo "======================================"
