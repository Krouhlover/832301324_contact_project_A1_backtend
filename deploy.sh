#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# 一键部署后端（Ubuntu）
# - 检查并安装：python3、python3-venv、python3-pip、sqlite3、curl
# - 创建并使用本地虚拟环境 .venv
# - 安装依赖 requirements.txt
# - 初始化数据库
# - 使用 systemd + gunicorn 常驻运行（0.0.0.0:5000）
#
# 使用：
#   chmod +x ./deploy.sh
#   ./deploy.sh
#
# 备注：脚本会使用 sudo 执行需要的系统级操作

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${PROJECT_DIR}/src"
SERVICE_NAME="contacts-backend"
PYTHON_BIN="python3"
VENV_DIR="${PROJECT_DIR}/.venv"
VENV_BIN="${VENV_DIR}/bin"
APP_MODULE="src.run:app"
APP_PORT="5000"

echo "==> 检测系统并按需安装必要组件（需要 sudo，仅在缺失时安装）..."
if ! command -v apt-get >/dev/null 2>&1; then
  echo "仅支持基于 apt 的 Ubuntu/Debian。请在 Ubuntu 上运行。"
  exit 1
fi

NEED_APT_UPDATE=0
ensure_pkg() {
  local CMD="$1"
  local PKG="$2"
  if ! command -v "$CMD" >/dev/null 2>&1; then
    NEED_APT_UPDATE=1
    PKGS_TO_INSTALL+=("$PKG")
  fi
}
PKGS_TO_INSTALL=()
ensure_pkg python3 python3
ensure_pkg sqlite3 sqlite3
ensure_pkg curl curl
# python3-venv 与 pip 用 dpkg 检测
if ! dpkg -s python3-venv >/dev/null 2>&1; then
  NEED_APT_UPDATE=1
  PKGS_TO_INSTALL+=("python3-venv")
fi
if ! command -v pip3 >/dev/null 2>&1; then
  NEED_APT_UPDATE=1
  PKGS_TO_INSTALL+=("python3-pip")
fi
if [ $NEED_APT_UPDATE -eq 1 ]; then
  echo "==> 正在安装缺失组件：${PKGS_TO_INSTALL[*]}"
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${PKGS_TO_INSTALL[@]}"
else
  echo "==> 所需组件已就绪，跳过 apt 安装。"
fi

echo "==> 创建/激活虚拟环境..."
if [ ! -d "${VENV_DIR}" ]; then
  "${PYTHON_BIN}" -m venv "${VENV_DIR}"
fi
"${VENV_BIN}/pip" install --upgrade pip

echo "==> 安装项目依赖..."
if [ -f "${PROJECT_DIR}/requirements.txt" ]; then
  "${VENV_BIN}/pip" install -r "${PROJECT_DIR}/requirements.txt"
else
  echo "未找到 requirements.txt，跳过依赖安装。"
fi

echo "==> 安装/检查 gunicorn..."
if ! "${VENV_BIN}/python" -c "import gunicorn" >/dev/null 2>&1; then
  "${VENV_BIN}/pip" install gunicorn
fi

echo "==> 数据库初始化..."
if [ -f "${PROJECT_DIR}/src/db_init.py" ]; then
  # 忽略输出中的 emoji 编码问题
  "${VENV_BIN}/python" "${PROJECT_DIR}/src/db_init.py" || true
else
  echo "未找到 src/db_init.py，跳过数据库初始化。"
fi

echo "==> 生成并安装 systemd 服务（需要 sudo）..."
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
sudo bash -c "cat > '${SERVICE_FILE}'" <<EOF
[Unit]
Description=Contacts Backend (Gunicorn)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${PROJECT_DIR}
Environment=PYTHONUNBUFFERED=1
Environment=PYTHONPATH=${SRC_DIR}
ExecStartPre=${VENV_BIN}/python ${PROJECT_DIR}/src/db_init.py
ExecStart=${VENV_BIN}/gunicorn --chdir ${PROJECT_DIR} --bind 0.0.0.0:${APP_PORT} --workers 2 --timeout 60 --access-logfile - --error-logfile - ${APP_MODULE}
Restart=always
RestartSec=2
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "==> 重新加载并启动服务..."
sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}" --now
sudo systemctl restart "${SERVICE_NAME}"
sudo systemctl status "${SERVICE_NAME}" --no-pager -l || true

echo "==> 获取公网 IP..."
PUBLIC_IP="$(curl -s http://checkip.amazonaws.com || curl -s ifconfig.me || echo '服务器公网IP')"

echo "==> 健康检查..."
if curl -fsS "http://127.0.0.1:${APP_PORT}/" >/dev/null 2>&1; then
  HEALTH="OK"
else
  HEALTH="FAILED"
fi

echo
echo "部署完成！"
echo "服务运行中："
echo "  - 本机:   http://127.0.0.1:${APP_PORT}/"
echo "  - 公网:   http://${PUBLIC_IP}:${APP_PORT}/"
echo "健康检查: ${HEALTH}"
echo
echo "常用命令："
echo "  查看状态: sudo systemctl status ${SERVICE_NAME}"
echo "  查看日志: journalctl -u ${SERVICE_NAME} -f"
echo "  重启服务: sudo systemctl restart ${SERVICE_NAME}"



