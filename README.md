初始化脚本
bash <(curl -fsSL https://raw.githubusercontent.com/torainya/xray/main/install.sh)

请输入域名:
xxx.torainya.com

#密码口令
请输入GLOBE_KEY:
xxxxxxxx

查看运行状态
systemctl status ddns

查看日志
tail -f /root/ddns/ddns.log

手动同步
bash /root/ddns/ddns-client.sh
