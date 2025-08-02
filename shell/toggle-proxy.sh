#!/bin/bash

# 定义代理服务器地址和端口
PROXY_HOST="127.0.0.1"
PROXY_PORT="7890"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
SOCKS5_URL="socks5://${PROXY_HOST}:${PROXY_PORT}"

# 检查当前的代理设置
current_http_proxy=$(env | grep -i http_proxy || echo "")
current_https_proxy=$(env | grep -i https_proxy || echo "")
current_socks_proxy=$(env | grep -i all_proxy || echo "")

# 如果已经设置了任何代理，则取消设置
if [ ! -z "$current_http_proxy" ] || [ ! -z "$current_https_proxy" ] || [ ! -z "$current_socks_proxy" ]; then
   echo "检测到已设置代理，正在取消..."
   
   # 取消所有代理设置
   unset http_proxy
   unset https_proxy
   unset all_proxy
   
   echo "已取消所有代理设置"
   
else
   # 如果没有设置代理，则设置新的代理
   echo "当前没有设置代理，正在设置..."
   
   # 设置 HTTP、HTTPS 和 SOCKS5 代理
   export http_proxy="${PROXY_URL}"
   export https_proxy="${PROXY_URL}"
   export all_proxy="${SOCKS5_URL}"
   
   echo "HTTP/HTTPS 代理已设置为 ${PROXY_URL}"
   echo "SOCKS5 代理已设置为 ${SOCKS5_URL}"
fi

# 显示当前的代理状态
echo -e "\n当前代理状态："
if [ -z "$(env | grep -i proxy)" ]; then
   echo "没有设置任何代理"
else
   env | grep -i --color=never proxy
fi
