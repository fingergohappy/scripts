#!/usr/bin/env bash
set -e

arg1="$1"   # 第一个参数：目录路径
arg2="$2"   # 第二个参数：目录路径（可选）

if [ -z "$arg1" ]; then
    echo "用法: $0 <arg1目录> [arg2目录]"
    exit 1
fi

# 将相对路径转换为绝对路径
arg1=$(realpath "$arg1")

# 取 arg1 目录名
arg1name=$(basename "$arg1")

# 如果 arg2 为空，用默认值（在arg1同级目录）
if [ -z "$arg2" ]; then
    parent_dir=$(dirname "$arg1")
    arg2="${parent_dir}/${arg1name}_workspace"
else
    # 将 arg2 相对路径转换为绝对路径
    # 如果是相对路径且目录不存在，先创建再转换
    if [[ "$arg2" != /* ]]; then
        mkdir -p "$arg2"
    fi
    arg2=$(realpath "$arg2")
fi

# 检查 arg2 目录是否存在，如果不存在则创建
if [ ! -d "$arg2" ]; then
    echo "创建目录: $arg2"
    mkdir -p "$arg2"
fi

# 在当前目录生成 run.sh
runsh="./replica_${arg1name}.sh"

cat > "$runsh" <<EOF
#!/usr/bin/env bash
set -e

name="\$1"

# 检查是否是 -list 参数
if [ "\$name" = "-list" ]; then
    echo "Workspace目录: $arg2"
    echo "所有子目录:"
    if [ ! -d "$arg2" ]; then
        echo "  (workspace目录不存在)"
    elif [ -z "\$(ls -A "$arg2")" ]; then
        echo "  (空)"
    else
        ls -1 "$arg2" | while read -r dir_name; do
            if [ -d "$arg2/\$dir_name" ]; then
                echo "  \$dir_name"
            fi
        done
    fi
    exit 0
fi

# 检查是否是 -d 参数
if [ "\$name" = "-d" ]; then
    delete_name="\$2"
    if [ -z "\$delete_name" ]; then
        echo "用法: \$0 -d <name>"
        exit 1
    fi
    
    target_dir="$arg2/\$delete_name"
    
    # 检查目录是否存在
    if [ ! -d "\$target_dir" ]; then
        echo "错误: 目录不存在 \$target_dir"
        exit 1
    fi
    
    echo "准备删除目录: \$target_dir"
    
    # 进入目录检查git状态
    cd "\$target_dir"
    
    # 检查是否有未提交的更改
    if [ -n "\$(git status --porcelain)" ]; then
        echo "发现未提交的更改:"
        git status --short
        echo ""
        read -p "是否自动提交这些更改? (y/N): " -n 1 -r
        echo ""
        if [[ \$REPLY =~ ^[Yy]\$ ]]; then
            echo "提交更改..."
            git add .
            git commit -m "Auto-commit before deletion"
            echo "更改已提交"
        else
            echo "取消删除操作"
            exit 1
        fi
    fi
    
    # 检查是否有未推送的提交
    # 先检查是否有上游分支
    upstream=\$(git rev-parse --abbrev-ref @{u} 2>/dev/null)
    if [ \$? -eq 0 ] && [ -n "\$upstream" ]; then
        # 检查是否有未推送的提交
        unpushed=\$(git rev-list @{u}..HEAD 2>/dev/null | wc -l)
        if [ "\$unpushed" -gt 0 ]; then
            echo "发现 \$unpushed 个未推送的提交"
            read -p "是否自动推送这些提交? (y/N): " -n 1 -r
            echo ""
            if [[ \$REPLY =~ ^[Yy]\$ ]]; then
                echo "推送提交..."
                # 获取远程仓库名称（通常是origin）
                remote=\$(git remote | head -1)
                if [ -z "\$remote" ]; then
                    echo "错误: 没有配置远程仓库"
                    exit 1
                fi
                # 推送当前分支到同名的远程分支
                git push "\$remote" HEAD
                echo "提交已推送"
            else
                echo "取消删除操作"
                exit 1
            fi
        fi
    else
        echo "没有设置上游分支，跳过推送检查"
    fi
    
    # 返回上级目录并删除
    cd ..
    rm -rf "\$delete_name"
    echo "目录已删除: \$target_dir"
    exit 0
fi

if [ -z "\$name" ]; then
    echo "用法: \$0 <name>"
    echo "      \$0 -list"
    echo "      \$0 -d <name>"
    exit 1
fi

git clone "$arg1" "${arg2}/\${name}"
cd "${arg2}/\${name}"
git checkout "\${name}" 2>/dev/null || git branch -m "\${name}"
EOF

chmod +x "$runsh"

echo "已生成 $runsh"

