#!/bin/bash

set -e

echo "======================================"
echo " Torainya Global DDNS Client "
echo " IPv4 + IPv6 Auto Update "
echo "======================================"

# ==============================
# 固定配置
# ==============================

WORKER_URL="https://ddns.torainya.com"


# ==============================
# 第一次运行配置
# ==============================

CONFIG_FILE="/root/ddns.conf"


if [ -f "$CONFIG_FILE" ]; then

    source "$CONFIG_FILE"

else

    echo ""
    read -p "请输入节点域名 (例如 vn.torainya.com): " DOMAIN

    read -p "请输入 GLOBE_KEY: " KEY


    if [ -z "$DOMAIN" ] || [ -z "$KEY" ]; then
        echo "域名或KEY不能为空"
        exit 1
    fi


    cat > "$CONFIG_FILE" <<EOF
DOMAIN="$DOMAIN"
KEY="$KEY"
EOF


    chmod 600 "$CONFIG_FILE"

fi


echo ""
echo "当前节点:"
echo "$DOMAIN"


# ==============================
# 获取IP
# ==============================


echo ""
echo "[1/3] 获取 IPv4..."

IPV4=$(curl -4 -s https://api.ipify.org)


if [ -z "$IPV4" ]; then
    echo "IPv4获取失败"
    exit 1
fi


echo "IPv4:"
echo "$IPV4"



echo ""
echo "[2/3] 获取 IPv6..."

IPV6=$(curl -6 -s https://api.ipify.org || true)


if [ -z "$IPV6" ]; then
    echo "IPv6不存在"
else
    echo "IPv6:"
    echo "$IPV6"
fi



# ==============================
# 上传Worker
# ==============================


echo ""
echo "[3/3] 同步 Cloudflare DNS..."


curl -s -X POST "$WORKER_URL" \
-H "Content-Type: application/json" \
-H "X-KEY: $KEY" \
-d "{
\"domain\":\"$DOMAIN\",
\"ipv4\":\"$IPV4\",
\"ipv6\":\"$IPV6\"
}"


echo ""

echo ""
echo "======================================"
echo " DDNS同步完成"
echo "======================================"


# ==============================
# 自动添加定时任务
# ==============================

CRON_JOB="0 */3 * * * /root/ddns-client.sh >/dev/null 2>&1"


if ! crontab -l 2>/dev/null | grep -q "ddns-client.sh"; then

    (
    crontab -l 2>/dev/null
    echo "$CRON_JOB"
    ) | crontab -

    echo "已添加3小时自动同步任务"

fi
