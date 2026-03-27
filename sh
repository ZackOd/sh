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
        echo "1 SMB安装并开机启动"
        echo "2 SMB配置(共享 /X 全权限)"
        echo "3 SMB服务状态查询"
        echo "4 重启 SMB"
        echo "5 删除配置并关闭启动"
        echo "6 返回"
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
                chmod -R 777 /X
                systemctl restart smbd
                log "SMB 配置已写入，并已设置 /X 权限为 777"
                ;;
            3)
                systemctl status smbd
                log "SMB 服务状态查询"
                ;;
            4)
                systemctl restart smbd
                log "SMB 服务已重启"
                ;;
            5)
                rm -f /etc/samba/smb.conf
                systemctl disable smbd
                log "SMB 配置已删除并关闭启动"
                ;;
            6) break ;;
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
                systemctl restart ssh
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
                apt update
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
        echo "1 创建xxx.service"
        echo "2 启动xxx服务"
        echo "3 查询状态"
        echo "4 创建胖墩墩超级备份系统"
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
                systemctl enable xxx
                log "xxx.service 已写入，设置开机启动"
                ;;
            2)
                systemctl restart xxx
                log "xxx 已重启"
                ;;
            3)
                systemctl status xxx
                log "查询 xxx 状态"
                ;;
            4)
                mkdir -p /X

                # 自动检测并安装 Go
                if ! command -v go >/dev/null 2>&1; then
                    log "未检测到 Go 环境，正在自动安装..."
                    apt update
                    apt install -y golang
                fi

                cat > /X/xxx.go <<'EOF'
package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"app/backup"
)

func main() {
	r := gin.Default()
	backup.RegisterBackupHandler(r, "/back_up", "/X")

	fmt.Println("http://localhost/back_up")

	r.Run(":80")
}
EOF
                log "xxx.go创建完成"

                # 进入 /X 目录执行编译
                cd /X || exit

                go mod init app
                go get github.com/gin-gonic/gin
                go mod tidy
                log "系统初始化完成"
                go build -o xxx xxx.go
                chmod +x xxx
                log "系统编译完成"
                
                mkdir -p /X/backup
                log "/X/backup创建完成"
                chmod -R 777 /X/backup
                log "/X/backup给予777权限"
                
                cat > /X/backup/backup.go <<'EOF'
package backup

import (
	"archive/tar"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

var (
	baseRoute string
	targetDir string
	backupDir string
)

// RegisterBackupHandler 注册备份插件路由 (适配 Gin 框架)
func RegisterBackupHandler(r *gin.Engine, route string, target string) {
	baseRoute = route
	targetDir = filepath.Clean(target)
	backupDir = filepath.Join(targetDir, "backup")

	os.MkdirAll(backupDir, 0755)

	// 使用 Gin 的路由组 (Group) 功能，结构更加清晰
	g := r.Group(baseRoute)
	{
		g.GET("", pageHandler)
		g.GET("/api/tree", withAuth(), treeHandler)
		g.POST("/api/backup", withAuth(), backupHandler)
		g.GET("/api/backups_list", withAuth(), listBackupsHandler)
		g.POST("/api/restore", withAuth(), restoreHandler)
		g.GET("/api/export", exportHandler) // 导出本身通过 URL 参数传验证码
		g.POST("/api/import", withAuth(), importHandler)
		g.POST("/api/clear", withAuth(), clearHandler)
	}
}

// ======================== 鉴权中间件 ========================
func verifyCode(code string) bool {
	if len(code) != 4 {
		return false
	}
	loc := time.FixedZone("CST", 8*3600)
	now := time.Now().In(loc)

	for i := -1; i <= 5; i++ {
		t := now.Add(time.Duration(i) * time.Minute)
		expected := t.Format("0415")
		if code == expected {
			return true
		}
	}
	return false
}

// withAuth 封装成 Gin 标准中间件
func withAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		code := c.GetHeader("X-Auth-Code")
		if !verifyCode(code) {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			return
		}
		c.Next()
	}
}

// ======================== 核心 API 逻辑 ========================

func pageHandler(c *gin.Context) {
	c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(htmlContent))
}

func treeHandler(c *gin.Context) {
	type Node struct {
		Name     string  `json:"name"`
		IsDir    bool    `json:"is_dir"`
		Size     string  `json:"size"`
		Date     string  `json:"date"`
		Children []*Node `json:"children"`
	}

	var buildNode func(path, name string, isDir bool) *Node
	buildNode = func(path, name string, isDir bool) *Node {
		node := &Node{Name: name, IsDir: isDir, Children: []*Node{}}
		
		if info, err := os.Stat(path); err == nil {
			node.Date = info.ModTime().Format("2006-01-02 15:04")
			if !isDir {
				sizeMB := float64(info.Size()) / (1024 * 1024)
				node.Size = fmt.Sprintf("%.2f MB", sizeMB)
			} else {
				node.Size = "-"
			}
		}

		if !isDir {
			return node
		}
		entries, err := os.ReadDir(path)
		if err == nil {
			for _, e := range entries {
				node.Children = append(node.Children, buildNode(filepath.Join(path, e.Name()), e.Name(), e.IsDir()))
			}
		}
		return node
	}

	info, err := os.Stat(targetDir)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	tree := buildNode(targetDir, targetDir, info.IsDir())
	c.JSON(http.StatusOK, tree)
}

func backupHandler(c *gin.Context) {
	loc := time.FixedZone("CST", 8*3600)
	filename := time.Now().In(loc).Format("200601021504") + "_backup.tar"
	outPath := filepath.Join(backupDir, filename)

	outFile, err := os.Create(outPath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer outFile.Close()

	tw := tar.NewWriter(outFile)
	defer tw.Close()

	filepath.Walk(targetDir, func(file string, fi os.FileInfo, err error) error {
		if err != nil { return err }
		if file == targetDir { return nil }
		
		if strings.HasPrefix(file, backupDir) {
			if fi.IsDir() { return filepath.SkipDir }
			return nil
		}

		header, err := tar.FileInfoHeader(fi, fi.Name())
		if err != nil { return err }

		relPath, _ := filepath.Rel(targetDir, file)
		header.Name = filepath.ToSlash(relPath)
		if err := tw.WriteHeader(header); err != nil { return err }

		if !fi.Mode().IsRegular() { return nil }
		f, err := os.Open(file)
		if err != nil { return err }
		defer f.Close()
		_, err = io.Copy(tw, f)
		return err
	})
	
	c.JSON(http.StatusOK, gin.H{"status": "ok", "file": filename})
}

func listBackupsHandler(c *gin.Context) {
	entries, _ := os.ReadDir(backupDir)
	var files []string
	for _, e := range entries {
		if strings.HasSuffix(e.Name(), "_backup.tar") {
			files = append(files, e.Name())
		}
	}
	// 如果 files 是 nil，Gin 默认序列化为 null，我们给它个空数组以防前端报错
	if files == nil {
		files = []string{}
	}
	c.JSON(http.StatusOK, files)
}

func restoreHandler(c *gin.Context) {
	filename := c.Query("file")
	if filename == "" || strings.Contains(filename, "/") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file"})
		return
	}
	tarPath := filepath.Join(backupDir, filename)

	entries, _ := os.ReadDir(targetDir)
	for _, e := range entries {
		fullPath := filepath.Join(targetDir, e.Name())
		if strings.HasPrefix(fullPath, backupDir) { continue }
		os.RemoveAll(fullPath)
	}

	f, err := os.Open(tarPath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer f.Close()
	tr := tar.NewReader(f)
	for {
		header, err := tr.Next()
		if err == io.EOF { break }
		if err != nil { continue }
		
		target := filepath.Join(targetDir, header.Name)
		if header.FileInfo().IsDir() {
			os.MkdirAll(target, 0755)
			continue
		}
		os.MkdirAll(filepath.Dir(target), 0755)
		outFile, _ := os.OpenFile(target, os.O_CREATE|os.O_RDWR, header.FileInfo().Mode())
		if outFile != nil {
			io.Copy(outFile, tr)
			outFile.Close()
		}
	}

	// 重启服务
	cmd := exec.Command("systemctl", "restart", "xxx")
	cmd.Run()

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func exportHandler(c *gin.Context) {
	if !verifyCode(c.Query("code")) {
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	filename := c.Query("file")
	if filename == "" || strings.Contains(filename, "/") {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"error": "Invalid file"})
		return
	}
	filePath := filepath.Join(backupDir, filename)
	
	// 使用 Gin 内置的附件下载与文件传输模块
	c.Header("Content-Disposition", "attachment; filename="+filename)
	c.Header("Content-Type", "application/x-tar")
	c.File(filePath)
}

func importHandler(c *gin.Context) {
	// Gin 获取上传文件非常简单
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Upload failed"})
		return
	}

	outPath := filepath.Join(backupDir, file.Filename)
	if err := c.SaveUploadedFile(file, outPath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func clearHandler(c *gin.Context) {
	entries, _ := os.ReadDir(backupDir)
	for _, e := range entries {
		if e.Name() == "backup.go" {
			continue
		}
		os.RemoveAll(filepath.Join(backupDir, e.Name()))
	}
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// ======================== HTML/CSS/JS ========================
const htmlContent = `
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>系统管理</title>
    <style>
        :root {
            --glass-bg: rgba(255, 255, 255, 0.25);
            --glass-border: rgba(255, 255, 255, 0.4);
            --text-color: #333;
        }
        body {
            margin: 0; padding: 0; 
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            height: 100vh; display: flex; align-items: center; justify-content: center; overflow: hidden;
            color: var(--text-color);
        }
        .glass-panel {
            background: var(--glass-bg);
            backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);
            border: 1px solid var(--glass-border);
            border-radius: 16px; box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        #login-view { width: 320px; padding: 40px; text-align: center; box-sizing: border-box; }
        .input-code {
            width: 100%; background: rgba(255,255,255,0.4); border: 1px solid var(--glass-border);
            padding: 12px; border-radius: 8px; outline: none; text-align: center;
            font-size: 1.5rem; letter-spacing: 8px; box-sizing: border-box; color: #333; transition: 0.3s;
        }
        .input-code:focus { background: rgba(255,255,255,0.7); }
        
        #dashboard-view {
            width: 85vw; height: 85vh; display: none; flex-direction: column; padding: 20px; box-sizing: border-box;
        }
        .header { display: flex; justify-content: space-between; margin-bottom: 20px; border-bottom: 1px solid var(--glass-border); padding-bottom: 10px;}
        .main-content { display: flex; flex: 1; overflow: hidden; gap: 20px; }
        
        .file-tree {
            flex: 2; padding: 20px; overflow-y: auto; 
            background: rgba(255,255,255,0.15); border-radius: 12px;
        }
        ul { list-style-type: none; padding-left: 20px; margin: 5px 0; }
        .tree-root { padding-left: 0; }
        
        li { margin: 8px 0; font-size: 0.95rem; }
        li::before { content: "📄 "; font-size: 0.9em; }
        li.is-dir::before { content: "📁 "; }
        
        .tree-row {
            display: inline-flex; width: calc(100% - 25px); 
            justify-content: space-between; align-items: center; vertical-align: bottom;
        }
        .tree-info {
            font-size: 0.8rem; color: #777; font-family: monospace; white-space: nowrap;
        }

        .actions { flex: 1; display: flex; flex-direction: column; gap: 15px; }
        .btn {
            background: rgba(255, 255, 255, 0.4); border: 1px solid var(--glass-border);
            border-radius: 8px; padding: 16px; cursor: pointer; transition: all 0.3s ease;
            font-size: 1rem; color: #333; text-align: center; font-weight: 500;
        }
        .btn:hover { background: rgba(255, 255, 255, 0.8); box-shadow: 0 4px 12px rgba(0,0,0,0.05); transform: translateY(-1px); }
        .btn:active { transform: translateY(1px); }

        .modal {
            display: none; position: fixed; top:0; left:0; width:100%; height:100%;
            background: rgba(0,0,0,0.2); backdrop-filter: blur(5px);
            align-items: center; justify-content: center; z-index: 999;
        }
        .modal-content { width: 400px; padding: 30px; max-width: 90vw; box-sizing: border-box;}
        .backup-item {
            padding: 10px; border-bottom: 1px solid var(--glass-border); cursor: pointer; word-break: break-all;
        }
        .backup-item:hover { background: rgba(255,255,255,0.5); }

        @media screen and (max-width: 768px) {
            #login-view { width: 90vw; padding: 30px 20px; }
            #dashboard-view { width: 96vw; height: 96vh; padding: 15px; }
            .header { margin-bottom: 10px; }
            .main-content { flex-direction: column; gap: 10px; }
            
            .actions {
                order: -1;          
                flex: none;         
                flex-direction: row;
                overflow-x: auto;   
                padding-bottom: 5px;
                gap: 8px;
            }
            .actions::-webkit-scrollbar { display: none; }
            .actions { -ms-overflow-style: none; scrollbar-width: none; }

            .btn {
                flex: 0 0 auto;     
                padding: 12px 15px; 
                font-size: 0.9rem;  
                white-space: nowrap;
            }

            .file-tree { flex: 1; padding: 10px; }
            .tree-row { flex-direction: column; align-items: flex-start; margin-bottom: 8px; }
            .tree-info { font-size: 0.75rem; margin-top: 4px; color: #888; }
        }
    </style>
</head>
<body>
    <div id="login-view" class="glass-panel">
        <h2 style="margin-top:0; font-weight: 400; font-size: 1.2rem; color: #555;">SECURITY</h2>
        <input type="password" id="auth-code" class="input-code" maxlength="4" placeholder="MMHH" autofocus>
    </div>

    <div id="dashboard-view" class="glass-panel">
        <div class="header">
            <span style="font-weight: 500; font-size: 1.2rem;">System Backup</span>
            <span style="font-size: 0.9rem; color: #666;" id="status-text">/X</span>
        </div>
        <div class="main-content">
            <div class="file-tree" id="tree-container">加载中...</div>
            <div class="actions">
                <button class="btn" onclick="doBackup()">备份</button>
                <button class="btn" onclick="showModal('restore')">还原</button>
                <button class="btn" onclick="showModal('export')">导出</button>
                <button class="btn" onclick="document.getElementById('file-input').click()">导入</button>
                <input type="file" id="file-input" style="display:none" onchange="doImport(this)">
                <button class="btn" onclick="doClear()" style="color: #d32f2f;">清理</button>
            </div>
        </div>
    </div>

    <div id="modal" class="modal">
        <div class="glass-panel modal-content">
            <h3 id="modal-title" style="margin-top:0;">Select Backup</h3>
            <div id="modal-list" style="max-height: 250px; overflow-y: auto; margin-bottom: 20px;"></div>
            <button class="btn" style="width: 100%; padding: 10px;" onclick="closeModal()">取消</button>
        </div>
    </div>

<script>
    let currentCode = '';
    const baseUri = window.location.pathname;

    document.getElementById('auth-code').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            currentCode = this.value;
            loadTree();
        }
    });

    async function apiCall(endpoint, options = {}) {
        if(!options.headers) options.headers = {};
        options.headers['X-Auth-Code'] = currentCode;
        
        const res = await fetch(baseUri + endpoint, options);
        if (res.status === 401) {
            alert("验证码过期或无效，请重新输入");
            window.location.reload();
            return null;
        }
        if (!res.ok) throw new Error("Request failed");
        return res.json();
    }

    async function loadTree() {
        const tree = await apiCall('/api/tree');
        if (!tree) return;
        
        document.getElementById('login-view').style.display = 'none';
        document.getElementById('dashboard-view').style.display = 'flex';

        function renderNode(node) {
            let html = '<li class="' + (node.is_dir ? 'is-dir' : '') + '">';
            html += '<div class="tree-row">';
            html += '<span>' + node.name + '</span>';
            html += '<span class="tree-info">' + (node.size || '-') + ' &nbsp;&nbsp;&nbsp; ' + (node.date || '') + '</span>';
            html += '</div>';
            
            if (node.is_dir && node.children && node.children.length > 0) {
                html += '<ul>' + node.children.map(renderNode).join('') + '</ul>';
            }
            html += '</li>';
            return html;
        }
        
        document.getElementById('tree-container').innerHTML = '<ul class="tree-root">' + renderNode(tree) + '</ul>';
    }

    async function doBackup() {
        setStatus("正在打包...");
        await apiCall('/api/backup', {method: 'POST'});
        setStatus("备份完成");
        loadTree();
    }

    let modalAction = '';
    async function showModal(action) {
        modalAction = action;
        const list = await apiCall('/api/backups_list');
        if(!list) return;

        document.getElementById('modal-title').innerText = action === 'restore' ? "选择要还原的备份" : "选择要导出的备份";
        const listDiv = document.getElementById('modal-list');
        listDiv.innerHTML = '';
        
        if(list.length === 0) { listDiv.innerHTML = '<div class="backup-item">暂无备份文件</div>'; }
        
        list.forEach(file => {
            let el = document.createElement('div');
            el.className = 'backup-item';
            el.innerText = file;
            el.onclick = () => handleModalSelect(file);
            listDiv.appendChild(el);
        });
        document.getElementById('modal').style.display = 'flex';
    }

    function closeModal() { document.getElementById('modal').style.display = 'none'; }

    async function handleModalSelect(file) {
        closeModal();
        if (modalAction === 'restore') {
            if(!confirm("警告：此操作将清空目标目录下除 backup 外的所有文件并解压覆盖！确认继续？")) return;
            setStatus("正在还原...");
            await apiCall('/api/restore?file=' + encodeURIComponent(file), {method: 'POST'});
            setStatus("还原成功");
            loadTree();
        } else if (modalAction === 'export') {
            window.location.href = baseUri + '/api/export?file=' + encodeURIComponent(file) + '&code=' + currentCode;
        }
    }

    async function doImport(input) {
        if (!input.files || input.files.length === 0) return;
        let formData = new FormData();
        formData.append("file", input.files[0]);
        setStatus("正在上传...");
        await fetch(baseUri + '/api/import', {
            method: 'POST',
            headers: { 'X-Auth-Code': currentCode },
            body: formData
        });
        input.value = '';
        setStatus("上传成功");
        loadTree();
    }

    async function doClear() {
        if(!confirm("确认要清空 backup 文件夹（除 backup.go 以外）的所有文件吗？")) return;
        setStatus("正在清理...");
        await apiCall('/api/clear', {method: 'POST'});
        setStatus("清理完成");
        loadTree();
    }

    function setStatus(text) {
        document.getElementById('status-text').innerText = text;
        setTimeout(() => { document.getElementById('status-text').innerText = '/X'; }, 3000);
    }
</script>
</body>
</html>
`
EOF
                log "/X/backup/backup.go创建完成"
                
                # 返回原始目录
                cd - > /dev/null

                systemctl restart xxx
                log "超级备份系统已启动: http://$(hostname -I | awk '{print $1}')/back_up"
                ;;
            5) break ;;
        esac
        pause
    done
}

# 启动
main_menu
