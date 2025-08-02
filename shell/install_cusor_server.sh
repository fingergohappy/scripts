#!/bin/bash

# 定义变量
VERSION="1.2.1"
COMMIT="031e7e0ff1e2eda9c1a0f5df67d44053b059c5d0"

# 系统信息 - 下载 linux 版本
OS="linux"
ARCH="x64"

# 检查是否安装了 sshpass
if ! command -v sshpass &> /dev/null; then
    echo "请先安装 sshpass:"
    echo "MacOS: brew install sshpass"
    echo "Ubuntu/Debian: sudo apt-get install sshpass"
    echo "CentOS/RHEL: sudo yum install sshpass"
    exit 1
fi

# 颜色输出
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 获取远程服务器信息
read -p "请输入远程服务器地址: " REMOTE_HOST
read -p "请输入远程服务器用户名 (默认: optuser): " REMOTE_USER
REMOTE_USER=${REMOTE_USER:-optuser}
read -s -p "请输入远程服务器密码: " REMOTE_PASS
echo ""

# 验证连接
echo -e "\n${GREEN}验证服务器连接...${NC}"
if ! sshpass -p "${REMOTE_PASS}" ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "echo '连接成功'"; then
    echo "连接服务器失败，请检查服务器地址、用户名和密码是否正确"
    exit 1
fi

# 本地临时目录
LOCAL_TEMP_DIR="/tmp/cursor-remote"
mkdir -p ${LOCAL_TEMP_DIR}

# 下载 URL
DOWNLOAD_URL="https://cursor.blob.core.windows.net/remote-releases/${VERSION}-${COMMIT}/vscode-reh-${OS}-${ARCH}.tar.gz"
PACKAGE_FILE="vscode-reh-${OS}-${ARCH}.tar.gz"
LOCAL_PACKAGE_PATH="${LOCAL_TEMP_DIR}/${PACKAGE_FILE}"

# 远程路径
REMOTE_BASE_DIR="/home/${REMOTE_USER}/.cursor-server"
REMOTE_SERVER_DIR="${REMOTE_BASE_DIR}/cli/servers/Stable-${COMMIT}/server"

# 打印信息
echo -e "${GREEN}开始安装 Cursor Remote Server...${NC}"
echo "版本: ${VERSION}"
echo "Commit: ${COMMIT}"
echo "目标服务器: ${REMOTE_HOST}"
echo "用户名: ${REMOTE_USER}"

# 在本地下载文件
echo -e "\n${GREEN}正在下载 vscode-reh 包到本地...${NC}"
curl -L "${DOWNLOAD_URL}" -o "${LOCAL_PACKAGE_PATH}"

if [ $? -ne 0 ]; then
    echo "下载包失败"
    rm -rf ${LOCAL_TEMP_DIR}
    exit 1
fi

# 在远程服务器创建目录
echo -e "\n${GREEN}在远程服务器创建目录...${NC}"
sshpass -p "${REMOTE_PASS}" ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_SERVER_DIR}"

if [ $? -ne 0 ]; then
    echo "创建远程目录失败"
    rm -rf ${LOCAL_TEMP_DIR}
    exit 1
fi

# 传输文件到远程服务器
echo -e "\n${GREEN}正在将文件复制到远程服务器...${NC}"
sshpass -p "${REMOTE_PASS}" scp -o StrictHostKeyChecking=no "${LOCAL_PACKAGE_PATH}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BASE_DIR}/"

if [ $? -ne 0 ]; then
    echo "复制文件到远程服务器失败"
    rm -rf ${LOCAL_TEMP_DIR}
    exit 1
fi

# 在远程服务器上解压文件
echo -e "\n${GREEN}在远程服务器上解压文件...${NC}"
sshpass -p "${REMOTE_PASS}" ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_SERVER_DIR} && tar -xzf ${REMOTE_BASE_DIR}/${PACKAGE_FILE} --strip-components=1 && rm ${REMOTE_BASE_DIR}/${PACKAGE_FILE}"

if [ $? -ne 0 ]; then
    echo "在远程服务器解压文件失败"
    rm -rf ${LOCAL_TEMP_DIR}
    exit 1
fi

# 清理本地临时文件
rm -rf ${LOCAL_TEMP_DIR}

echo -e "\n${GREEN}安装成功完成！${NC}"
echo "Cursor Remote Server 已安装到: ${REMOTE_SERVER_DIR}"
