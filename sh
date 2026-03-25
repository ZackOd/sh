#!/bin/bash

LOG_FILE="/var/log/xxx_menu.log"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "$(date '+%F %T') $1" | tee -a "$LOG_FILE"
}

pause() {
    read -p "按回车继续..."
}

# ================= 主菜单 =================
main_menu() {
    while true; do
        clear
        echo -e "${CYAN}===== 主菜单 =====${NC}"
        echo -e "${GREEN}1 SMB${NC}"
        echo -e "${YELLOW}2 Docker${NC}"
        echo -e "${BLUE}3 SSH${NC}"
        echo -e "${MAGENTA}4 GO${NC}"
        echo -e "${CYAN}5 服务项${NC}"
        echo -e "${RED}6 取消${NC}"
        read -p "请选择: " choice

        case $choice in
            1) smb_menu ;;
            2) docker_menu ;;
            3) ssh_menu ;;
            4) go_menu ;;
            5) service_menu ;;
            6) exit 0 ;;
        esac
    done
}

# ================= SMB =================
smb_menu() {
    while true; do
        clear
        echo -e "${GREEN}===== SMB 菜单 =====${NC}"
        echo "1 安装并开机启动"
        echo "2 写配置(共享 /X 全权限)"
        echo "3 重启 SMB"
        echo "4 删除配置并关闭启动"
        echo "5 返回"
        read -p "选择: " c

        case $c in
            1)
                apt update
                apt install -y samba
                systemctl enable smbd
                log "SMB 已安装并设置开机启动"
                ;;
            2)
                mkdir -p /X
                cat > /etc/samba/smb.conf <<EOF
[global]
workgroup = WORKGROUP
security = user
map to guest = Bad User

[X]
path = /X
browseable = yes
read only = no
guest ok = yes
create mask = 0777
directory mask = 0777
EOF
                log "SMB 配置已写入"
                ;;
            3)
                systemctl restart smbd
                log "SMB 服务已重启"
                ;;
            4)
                rm -f /etc/samba/smb.conf
                systemctl disable smbd
                log "SMB 配置已删除并关闭启动"
                ;;
            5) break ;;
        esac
        pause
    done
}

# ================= Docker =================
docker_menu() {
    while true; do
        clear
        echo -e "${YELLOW}===== Docker 菜单 =====${NC}"
        echo "1 安装 Docker"
        echo "2 重启 Docker"
        echo "3 返回"
        read -p "选择: " c

        case $c in
            1)
                curl -fsSL https://get.docker.com -o get-docker.sh
                sh get-docker.sh
                log "Docker 安装完成"
                ;;
            2)
                systemctl restart docker
                log "Docker 已重启"
                ;;
            3) break ;;
        esac
        pause
    done
}

# ================= SSH =================
ssh_menu() {
    while true; do
        clear
        echo -e "${BLUE}===== SSH 菜单 =====${NC}"
        echo "1 安装并启用 SSH"
        echo "2 强制写入配置"
        echo "3 查询状态"
        echo "4 重启 SSH"
        echo "5 返回"
        read -p "选择: " c

        case $c in
            1)
                apt install -y openssh-server
                systemctl enable ssh
                log "SSH 已安装并开机启动"
                ;;
            2)
                sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
                sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
                log "SSH 配置已写入"
                ;;
            3)
                systemctl status ssh
                log "SSH 状态查询"
                ;;
            4)
                systemctl restart ssh
                log "SSH 已重启"
                ;;
            5) break ;;
        esac
        pause
    done
}

# ================= GO =================
go_menu() {
    while true; do
        clear
        echo -e "${MAGENTA}===== GO 菜单 =====${NC}"
        echo "1 安装 GO"
        echo "2 返回"
        read -p "选择: " c

        case $c in
            1)
                apt install -y golang
                log "GO 已安装"
                ;;
            2) break ;;
        esac
        pause
    done
}

# ================= 服务 =================
service_menu() {
    while true; do
        clear
        echo -e "${CYAN}===== 服务菜单 =====${NC}"
        echo "1 写 xxx.service"
        echo "2 开机启动"
        echo "3 查询状态"
        echo "4 重启服务"
        echo "5 返回"
        read -p "选择: " c

        case $c in
            1)
cat << 'EOF' > /etc/systemd/system/xxx.service
[Unit]
Description=Docker Cluster Management System
After=network.target

[Service]
WorkingDirectory=/X
ExecStart=/X/xxx
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                log "xxx.service 已写入"
                ;;
            2)
                systemctl enable xxx
                log "xxx 已设置开机启动"
                ;;
            3)
                systemctl status xxx
                log "查询 xxx 状态"
                ;;
            4)
                systemctl restart xxx
                log "xxx 已重启"
                ;;
            5) break ;;
        esac
        pause
    done
}

# 启动
main_menu
