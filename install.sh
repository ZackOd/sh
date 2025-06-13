#!/bin/bash

# ----------------------------
# 系统初始化脚本
# 功能：更新系统、安装常用软件、设置 root 密码、更改 SSH 端口、配置 fail2ban
# ----------------------------

# 设置变量
NEW_PASSWORD='Z5@zCWb6p!q'
NEW_SSH_PORT=39393
SSHD_CONFIG="/etc/ssh/sshd_config"
FAIL2BAN_CONFIG="/etc/fail2ban/jail.local"

# 检查是否为 root 用户
if [[ $EUID -ne 0 ]]; then
   echo "❌ 请以 root 用户身份运行此脚本。" 
   exit 1
fi

# 第一步：系统更新和软件安装
echo "📦 开始更新系统并安装常用软件..."
apt update && apt upgrade -y && apt install curl wget nano unzip sudo fail2ban iptables -y

if [[ $? -eq 0 ]]; then
    echo "✅ 系统更新与软件安装完成"
else
    echo "❌ 系统更新失败，请检查网络或软件源配置"
    exit 1
fi

# 第二步：设置 root 密码
echo "🔐 正在设置 root 密码..."
echo "root:$NEW_PASSWORD" | chpasswd
if [[ $? -eq 0 ]]; then
    echo "密码已经变更完成 ✅"
else
    echo "❌ 密码更改失败"
    exit 1
fi

# 第三步：修改 SSH 端口
echo "🔧 正在修改 SSH 端口为 $NEW_SSH_PORT..."

# 备份 ssh 配置文件
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%F-%T)"

# 修改端口配置
if grep -q "^#Port " "$SSHD_CONFIG"; then
    sed -i "s/^#Port .*/Port $NEW_SSH_PORT/" "$SSHD_CONFIG"
elif grep -q "^Port " "$SSHD_CONFIG"; then
    sed -i "s/^Port .*/Port $NEW_SSH_PORT/" "$SSHD_CONFIG"
else
    echo "Port $NEW_SSH_PORT" >> "$SSHD_CONFIG"
fi

# 重启 SSH 服务
echo "🔁 正在重启 SSH 服务..."
if systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null; then
    echo "SSH已经变更完成 ✅"
else
    echo "❌ SSH 服务重启失败，请检查配置"
    exit 1
fi

# 第四步：配置 fail2ban
echo "🛡️ 正在配置 fail2ban..."

cat > "$FAIL2BAN_CONFIG" <<EOF
[sshd]
enabled = true
port = $NEW_SSH_PORT
findtime = 30m
maxretry = 3
bantime = 365d
ignoreip = 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12 127.0.0.1/8 ::1
logpath = /var/log/auth.log
backend = %(sshd_backend)s
EOF

# 启用并重启 fail2ban 服务
systemctl enable fail2ban
systemctl restart fail2ban

if [[ $? -eq 0 ]]; then
    echo "Fail2ban配置完成 ✅"
else
    echo "❌ Fail2ban 启动失败，请检查配置"
    exit 1
fi
