#!/usr/bin/env bash

# 设置字符编码
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 脚本: ssh-setup.sh
# 功能: 设置SSH连接,复制公钥到远程服务器,并更新SSH配置文件

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # 恢复默认颜色

# 检查ssh-copy-id命令是否存在
if ! command -v ssh-copy-id &> /dev/null; then
    printf "${RED}错误: 未找到ssh-copy-id命令${NC}\n"
    printf "请安装openssh-client(Linux)或通过Homebrew安装(MacOS)\n"
    exit 1
fi

# 函数:列出并选择SSH密钥
select_ssh_key() {
    local ssh_dir=~/.ssh
    declare -a keys=()
    declare -a key_paths=()
    
    # 查找公钥文件
    printf "${BLUE}正在查找SSH密钥...${NC}\n" >&2
    printf "${BLUE}搜索目录: %s${NC}\n\n" "$ssh_dir" >&2
    
    # 直接列出所有.pub文件
    shopt -s nullglob
    local pub_files
    pub_files=("$ssh_dir"/*.pub)
    shopt -u nullglob
    
    # 如果没有找到任何密钥
    if [ ${#pub_files[@]} -eq 0 ]; then
        printf "${BLUE}未找到SSH公钥,需要先生成一个${NC}\n" >&2
        read -p "是否现在生成SSH密钥? (y/n): " gen_key >&2
        if [[ "$gen_key" =~ ^[Yy]$ ]]; then
            ssh-keygen -t ed25519
            # 重新调用本函数来列出新生成的密钥
            select_ssh_key
            return
        else
            printf "${RED}未生成SSH密钥,脚本退出${NC}\n" >&2
            exit 1
        fi
    fi

    # 处理找到的密钥
    for pubkey in "${pub_files[@]}"; do
        local key_name=$(basename "$pubkey" .pub)
        keys+=("$key_name")
        key_paths+=("$ssh_dir/$key_name")
    done

    # 显示可用的密钥列表
    printf "${GREEN}可用的SSH密钥:${NC}\n" >&2
    printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" >&2
    for i in "${!keys[@]}"; do
        local key_info=$(ssh-keygen -lf "${key_paths[$i]}.pub" 2>/dev/null)
        local key_type=$(ssh-keygen -lf "${key_paths[$i]}.pub" 2>/dev/null | awk '{print $NF}' | tr -d '()')
        local key_bits=$(ssh-keygen -lf "${key_paths[$i]}.pub" 2>/dev/null | awk '{print $1}')
        local key_fingerprint=$(ssh-keygen -lf "${key_paths[$i]}.pub" 2>/dev/null | awk '{print $2}')
        
        printf "${BLUE}%d.${NC} ${GREEN}%s${NC}\n" "$((i+1))" "${keys[$i]}" >&2
        if [ -n "$key_info" ]; then
            printf "   类型: %s  位数: %s\n" "${key_type:-Unknown}" "${key_bits:-Unknown}" >&2
            printf "   指纹: %s\n" "${key_fingerprint:-Unknown}" >&2
        else
            printf "   ${RED}无法读取密钥信息${NC}\n" >&2
        fi
        printf "\n" >&2
    done
    printf "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n" >&2

    # 让用户选择密钥
    while true; do
        printf "${BLUE}请选择要使用的SSH密钥 (1-${#keys[@]}): ${NC}" >&2
        read choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#keys[@]}" ]; then
            selected_key="${key_paths[$((choice-1))]}"
            printf "${GREEN}✓ 已选择密钥: ${keys[$((choice-1))]}${NC}\n" >&2
            printf "${BLUE}  密钥路径: ${selected_key}${NC}\n" >&2
            break
        else
            printf "${RED}✗ 无效的选择,请输入1到${#keys[@]}之间的数字${NC}\n" >&2
        fi
    done

    printf "%s" "$selected_key"
}

# 获取用户选择的SSH密钥
selected_key=$(select_ssh_key)
if [ -z "$selected_key" ]; then
    printf "${RED}未选择SSH密钥,脚本退出${NC}\n"
    exit 1
fi

# 获取用户输入
printf "\n${GREEN}===== SSH连接设置 =====${NC}\n"
read -p "请输入远程服务器IP地址: " ip_address
read -p "请输入远程服务器用户名: " username
read -s -p "请输入远程服务器密码: " password
echo

# 函数:检查别名是否存在
check_alias() {
    local alias=$1
    if [ -f ~/.ssh/config ] && grep -q "^Host[[:space:]]*$alias\$" ~/.ssh/config; then
        return 0  # 别名存在
    else
        return 1  # 别名不存在
    fi
}

# 获取并验证别名
while true; do
    read -p "请输入别名(可选,用于SSH配置): " alias_name
    
    # 如果用户没有输入别名,直接跳出循环
    if [ -z "$alias_name" ]; then
        break
    fi
    
    # 检查别名是否已存在
    if check_alias "$alias_name"; then
        printf "${RED}错误: 别名 '$alias_name' 已存在,请输入其他别名${NC}\n"
    else
        break
    fi
done

# 使用sshpass调用ssh-copy-id
printf "${BLUE}正在将SSH公钥复制到远程服务器...${NC}\n"
if command -v sshpass &> /dev/null; then
    sshpass -p "$password" ssh-copy-id -o StrictHostKeyChecking=no -i "${selected_key}.pub" "$username@$ip_address"
else
    printf "${BLUE}sshpass未安装,使用常规方式。请在提示时输入密码:${NC}\n"
    ssh-copy-id -o StrictHostKeyChecking=no -i "${selected_key}.pub" "$username@$ip_address"
fi

# 检查ssh-copy-id是否成功
if [ $? -eq 0 ]; then
    printf "${GREEN}SSH公钥已成功复制到远程服务器${NC}\n"
    
    # 更新SSH配置文件
    if [ -n "$alias_name" ]; then
        printf "${BLUE}正在更新SSH配置文件...${NC}\n"
        
        # 确保.ssh目录和config文件存在
        mkdir -p ~/.ssh
        touch ~/.ssh/config
        
        # 添加配置到SSH配置文件
        printf "\nHost %s\n    HostName %s\n    User %s\n    IdentityFile %s\n" \
            "$alias_name" "$ip_address" "$username" "$selected_key" >> ~/.ssh/config
        
        printf "${GREEN}SSH配置已更新,现在可以使用 'ssh %s' 连接到服务器${NC}\n" "$alias_name"
    else
        printf "${BLUE}未提供别名,SSH配置文件未更新${NC}\n"
    fi
    
    printf "${GREEN}设置完成! 现在可以无密码SSH登录到 %s@%s${NC}\n" "$username" "$ip_address"
else
    printf "${RED}复制SSH密钥失败${NC}\n"
    exit 1
fi