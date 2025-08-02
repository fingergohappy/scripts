#!/bin/bash

# 脚本: ssh-setup.sh
# 功能: 设置SSH连接,复制公钥到远程服务器,并更新SSH配置文件

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # 恢复默认颜色

# 检查ssh-copy-id命令是否存在
if ! command -v ssh-copy-id &> /dev/null; then
    echo -e "${RED}错误: 未找到ssh-copy-id命令${NC}"
    echo "请安装openssh-client(Linux)或通过Homebrew安装(MacOS)"
    exit 1
fi

# 检查是否有SSH密钥
if [ ! -f ~/.ssh/id_rsa.pub ] && [ ! -f ~/.ssh/id_ed25519.pub ]; then
    echo -e "${BLUE}未找到SSH公钥,需要先生成一个${NC}"
    read -p "是否现在生成SSH密钥? (y/n): " gen_key
    if [[ "$gen_key" =~ ^[Yy]$ ]]; then
        ssh-keygen -t ed25519
    else
        echo -e "${RED}未生成SSH密钥,脚本退出${NC}"
        exit 1
    fi
fi

# 获取用户输入
echo -e "${GREEN}===== SSH连接设置 =====${NC}"
read -p "请输入远程服务器IP地址: " ip_address
read -p "请输入远程服务器用户名: " username
read -s -p "请输入远程服务器密码: " password
echo
read -p "请输入别名(可选,用于SSH配置): " alias_name

# 使用sshpass调用ssh-copy-id
echo -e "${BLUE}正在将SSH公钥复制到远程服务器...${NC}"
if command -v sshpass &> /dev/null; then
    sshpass -p "$password" ssh-copy-id -o StrictHostKeyChecking=no "$username@$ip_address"
else
    echo -e "${BLUE}sshpass未安装,使用常规方式。请在提示时输入密码:${NC}"
    ssh-copy-id -o StrictHostKeyChecking=no "$username@$ip_address"
fi

# 检查ssh-copy-id是否成功
if [ $? -eq 0 ]; then
    echo -e "${GREEN}SSH公钥已成功复制到远程服务器${NC}"
    
    # 更新SSH配置文件
    if [ -n "$alias_name" ]; then
        echo -e "${BLUE}正在更新SSH配置文件...${NC}"
        
        # 确保.ssh目录和config文件存在
        mkdir -p ~/.ssh
        touch ~/.ssh/config
        
        # 添加配置到SSH配置文件
        echo -e "\nHost $alias_name\n    HostName $ip_address\n    User $username\n    IdentityFile ~/.ssh/id_rsa" >> ~/.ssh/config
        
        echo -e "${GREEN}SSH配置已更新,现在可以使用 'ssh $alias_name' 连接到服务器${NC}"
    else
        echo -e "${BLUE}未提供别名,SSH配置文件未更新${NC}"
    fi
    
    echo -e "${GREEN}设置完成! 现在可以无密码SSH登录到 $username@$ip_address${NC}"
else
    echo -e "${RED}复制SSH密钥失败${NC}"
    exit 1
fi
