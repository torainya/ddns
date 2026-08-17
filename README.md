3X-UI脚本
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

前置脚本
bash <(wget -qO- -o- https://github.com/233boy/Xray/raw/main/install.sh)

初始化脚本
bash <(curl -fsSL https://raw.githubusercontent.com/torainya/ddns/main/install.sh)

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
