
#!/bin/bash

# Cursor 远程连接脚本
# 接收参数格式: ganesha:/home/finger/code/metac

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法: $0 <host>:<path>"
    echo "示例: $0 ganesha:/home/finger/code/metac"
    exit 1
fi

# 解析参数
IFS=':' read -r host path <<< "$1"

# 检查参数格式
if [ -z "$host" ] || [ -z "$path" ]; then
    echo "错误: 参数格式不正确"
    echo "正确格式: <host>:<path>"
    echo "示例: ganesha:/home/finger/code/metac"
    exit 1
fi

# 执行 Cursor 远程连接命令
echo "正在连接到 $host:$path ..."
cursor --remote ssh-remote+$host $path