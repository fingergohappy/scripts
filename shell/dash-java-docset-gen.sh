#!/bin/zsh

function get_download_path(){
  #  pkg:maven/org.springframework.data/spring-data-mongodb@4.3.5 -> /org.springframework.data/spring-data-mongodb
    local input="$1"
    
    # 检查输入是否为空
    if [ -z "$input" ]; then
        echo "Error: Empty input" >&2
        return 1
    fi
    
    # 检查输入格式
    if [[ ! $input =~ ^pkg:maven/.+@[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid format" >&2
        return 1
    fi
    
    local result="$input"
    
    # 移除pkg:maven/
    result=${result#pkg:maven/}
    
    # 分离@前后的部分
    local prefix="${result%@*}"
    local version="${result#*@}"
    
    # 替换.为/
    prefix=${prefix//.//}
    
    # 组合结果
    result="$prefix/$version"
    # 获取java doc包名称
    
    echo "${result}"
    return 0
}

source $HOME/shell/toggle-proxy.sh
# jar包临时存放路径
temp_jar_path="${HOME}/code/dash/docset/java/temp-jar"

maven_repo="https://repo1.maven.org/maven2"

javadocset_cmd_path=$HOME/code/dash/docset/java/javadocset 

# example : pkg:maven/org.springframework.data/spring-data-mongodb@4.3.5
package_url=$1
echo begin generate java docset for $package_url

# 获取jar包名称
# pkg:maven/org.springframework.data/spring-data-mongodb@4.3.5
# -> org.springframework.data/spring-data-mongodb@4.3.5
project_and_version=$(echo $package_url | cut -d'/' -f3)

# pkg:maven/org.springframework.data/spring-data-mongodb@4.3.5
# -> spring-data-mongodb-4.3.5-javadoc.jar
doc_jar_name=$(echo "$package_url" | sed 's/.*\///' | sed 's/@/-/g')"-javadoc.jar"

echo proect_and_version is $project_and_version
echo doc jar name is $doc_jar_name

# 判断jar包名称在 如果存在,则删除

if [ ! -d $temp_jar_path ]; then
    mkdir -p $temp_jar_path
fi
echo chek file is ${temp_jar_path}/$doc_jar_name
if [ -f $temp_jar_path/$doc_jar_name ]; then
  echo $temp_jar_path/$doc_jar_name
  rm -f $temp_jar_path/$doc_jar_name
  rm -rf "$temp_jar_path/$doc_jar_name".unzip
  echo "have save faile File deleted"
fi
# 获取完整路径
download_path=$(get_download_path $package_url)/$doc_jar_name

echo "doc jar download_path is ${maven_repo}/${download_path},begin down"


# #开始下载jar包
wget -P $temp_jar_path ${maven_repo}/${download_path}
# # 解压jar包
unzip  $temp_jar_path/$doc_jar_name  -d $temp_jar_path/$doc_jar_name".unzip"
# 调用命令生成docset


echo begin generate docset
cd $temp_jar_path
$javadocset_cmd_path ${project_and_version} $temp_jar_path/${doc_jar_name}.unzip
# # 移动docset到dash目录
cp -rf $temp_jar_path/${project_and_version}.docset $HOME/code/dash/docset/java/docset
#
# # 删除临时文件
rm -rf $temp_jar_path/*
#
#

