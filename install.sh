#!/bin/bash
# 更新系统
echo "开始更新系统..."
sudo apt update -y
echo "完成更新系统"

# 安装 curl 和 wget
echo "开始安装 curl 和 wget..."
sudo apt install -y curl wget
echo "完成安装 curl 和 wget"

# 修改系统时区为 Asia/Shanghai
echo "开始修改系统时区为 Asia/Shanghai..."
sudo timedatectl set-timezone Asia/Shanghai
echo "完成时区修改"

# 安装 fail2ban
echo "开始安装 fail2ban..."
apt install fail2ban -y
echo "完成安装 fail2ban"

# 安装 vnstat 
apt-get install vnstat jq -y 
echo "完成安装 vnstat"
systemctl enable vnstat
echo "设置开机启动 vnstat"
