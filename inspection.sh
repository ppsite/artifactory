#!/bin/bash
set -e
echo "请输入artifactory的URL：（如http://ip:8082）"
read url
echo "请输入artifactory的管理员账号："
read user
echo "密码："
read -s passwd
echo "这是artifactory机器还是xray机器？"
echo "1. artifactory"
echo "2. xray"
read -p "请选择1或2：" machine_type

# 安装 epel-release 软件包
yum install -y epel-release &>/dev/null
package_name=$(yum search jq | awk '/jq.x86_64/ || /jq.aarch64/ {print $1}')
if [[ -n "$package_name" ]]; then
    echo "Installing jq ..."
    sudo yum install -y "$package_name" &>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "jq package has been installed."
    else
        echo "Failed to install jq."
    fi
else
    echo "jq package not found."
fi


cmd1=$(hostname)
cmd2=$(uname -r)
cmd3=$(dmidecode | grep Product)
cmd4=$(cat /etc/os-release)
cmd5=$(uptime | cut -d " " -f 4-6 |cut -d  "," -f  1-2)
cmd6=$(nproc)
cmd7=$(free -h | grep 'Mem:' | awk '{print $2}')
cmd8=$(free -h | grep 'Swap:' | awk '{print $3}')
cmd9=$(df -hT)
cmd10=$(curl -s -u$user:$passwd -X GET $url/artifactory/api/system/license | jq '.type, .validThrough')
cmd11=$(curl -s -u$user:$passwd -X GET $url/xray/api/v1/gc/status | jq)
cmd12=$(curl -s -u$user:$passwd -X GET $url/xray/api/v1/configuration/gc | jq)
cmd13=$(curl -s -u$user:$passwd -X GET $url/xray/api/v2/watches | jq)
cmd14=$(curl -s -u$user:$passwd -X GET $url/xray/api/v2/policies | jq)
cmd15=$(curl -s -u$user:$passwd -XPOST -H "Content-Type: application/json" -d '{"pagination":{"order_by":"updated"}}'  $url/xray/api/v1/violations | jq)
cmd16=$(curl -s -u$user:$passwd -XGET $url/xray/api/v1/ignore_rules | jq)



# 结果输出
if [ "$machine_type" = "1" ]; then
	cmd17=$(curl -s -u$user:$passwd -X GET $url/artifactory/api/storageinfo | jq '.binariesSummary.binariesCount')
	cmd18=$(curl -s -u$user:$passwd -X GET $url/artifactory/api/storageinfo | jq '.binariesSummary.artifactsCount')
	cmd19=$(curl -s -u$user:$passwd -X GET $url/artifactory/api/storageinfo | jq '.binariesSummary.itemsCount')
	cmd23=$(cat $path/var/etc/system.yaml |grep -A6 "artifactory" | grep -A4 "tomcat" | grep -A2 "connector" | grep  "maxThreads" | awk  "{print \$2}")
	cmd24=$(cat $path/var/etc/system.yaml |grep -A6 "access" | grep -A4 "tomcat" | grep -A2 "connector" | grep  "maxThreads" | awk  "{print \$2}")
	cmd25=$(cat $path/var/etc/system.yaml |grep -A6 "access" | grep -A4 "tomcat" | grep -A2 "connector" | grep  "maxThreads" | awk  "{print \$2}")
	cmd26=$(cat $path/var/etc/system.yaml |grep -A6 "artifactory" | grep -A4 "database" | grep  "maxOpenConnections" | awk  "{print \$2}")
	cmd27=$(cat $path/var/etc/system.yaml |grep -A6 "access" | grep -A4 "database" | grep  "maxOpenConnections" | awk  "{print \$2}")
	cmd28=$(cat $path/var/etc/system.yaml |grep -A6 "metadata" | grep -A4 "database" | grep  "maxOpenConnections" | awk  "{print \$2}")
	cmd29=$(grep -o '<maxCacheSize>.*</maxCacheSize>'  $path/var/etc/artifactory/binarystore.xml | sed 's/<maxCacheSize>\(.*\)<\/maxCacheSize>/\1/'| awk '{ printf "%.2f G\n", $1/1024/1024/1024 }')
	cmd30=$(grep -o '<cacheProviderDir>.*</cacheProviderDir>' $path/var/etc/artifactory/binarystore.xml | sed 's/<cacheProviderDir>\(.*\)<\/cacheProviderDir>/\1/')
	echo "请输入artifactory路径：（如/opt/artifactory）"
	read path
	echo "主机名: ${cmd1}" | tee -a output.txt
	echo "内核版本: ${cmd2}" | tee -a output.txt
	echo "服务器型号: ${cmd3}" | tee -a output.txt
	echo "系统版本: ${cmd4}" | tee -a output.txt
	echo "系统运行时间: ${cmd5}" | tee -a output.txt
	echo "CPU核数:  ${cmd6}" | tee -a output.txt
	echo "内存： ${cmd7}" | tee -a output.txt
	echo "swap使用: ${cmd8}" | tee -a output.txt
	echo "文件系统空间使用情况:" | tee -a output.txt
	echo "${cmd9}" | tee -a output.txt
	echo "artifactory版本：$(curl -s -u$user:$passwd -X GET $url/artifactory/api/system/version | jq -r ".version") " | tee -a output.txt

	if rpm -qa | grep -q "artifactory"; then
		echo "安装类型：使用rpm安装" | tee -a output.txt
	else
		echo "安装类型：使用tar安装" | tee -a output.txt
	fi

	echo "许可证类型及到期时间:" | tee -a output.txt
	echo " ${cmd10}" | tee -a output.txt
	echo "二进制包数量：${cmd17}" | tee -a output.txt
	echo "制品数量：${cmd18}" | tee -a output.txt
	echo "所有制品及文件夹数量：${cmd19}" | tee -a output.txt


	if [ -z "${cmd23}" ]; then
		echo "Artifactory最大线程：未配置，使用默认值200" | tee -a output.txt
	else
		echo "Artifactory最大线程：${cmd23}" | tee -a output.txt
	fi


	if [ -z "${cmd24}" ]; then
		echo "Access最大线程：未配置，使用默认值50" | tee -a output.txt
	else
		echo "Access最大线程：${cmd24}" | tee -a output.txt
	fi


	if [ -z "${cmd25}" ]; then
		echo "Artifactory与Access最大链接：未配置，使用默认值50" | tee -a output.txt
	else
		echo "Artifactory与Access最大链接：${cmd25}" | tee -a output.txt
	fi


	if [ -z "${cmd26}" ]; then
		echo "Artifactory数据库最大链接：未配置，使用默认值100" | tee -a output.txt
	else
		echo "Artifactory数据库最大链接：${cmd26}" | tee -a output.txt
	fi


	if [ -z "${cmd27}" ]; then
		echo "Access数据库最大链接：未配置，使用默认值100" | tee -a output.txt
	else
		echo "Access数据库最大链接：${cmd27}" | tee -a output.txt
	fi


	if [ -z "${cmd28}" ]; then
		echo "Metadata数据库最大链接：未配置，使用默认值100" | tee -a output.txt
	else
		echo "Metadata数据库最大链接：${cmd28}" | tee -a output.txt
	fi

	#获取cache所在磁盘信息
	echo "cache设定大小：${cmd29}" | tee -a output.txt
	echo "cache文件夹：${cmd30}" | tee -a output.txt
	folder_path="${cmd30}"
	folder_size=$(du -s "$folder_path" | awk '{print $1}')
	folder_size_gb=$(echo "scale=2; $folder_size/1024/1024" | bc)
	#获取cache所在磁盘
	folder_disk=$(df -h "$folder_path" | awk 'NR==2 {print $1}')
	# 获取cache所在磁盘的总大小
	folder_disk_size=$(df -h "$folder_path" | awk 'NR==2 {print $2}')
	echo "文件夹所在磁盘: $folder_disk" | tee -a output.txt
	echo "文件夹所在磁盘总大小: $folder_disk_size" | tee -a output.txt

	#获取S3的HTTP最大线程数
	value=$(grep 'name="httpclient.max-connections"' $path/var/etc/artifactory/binarystore.xml  | awk -F 'value="' '{print $2}' | awk -F '"' '{print $1}')
	# 或使用 grep 和 sed 提取配置值
	# value=$(grep 'name="httpclient.max-connections"' config.xml | sed 's/.*value="\([^"]*\)".*/\1/')
	if [ -z "$value" ]; then
		# 如果未获取到值，则显示默认值
		echo "S3存储HTTP最大线程数：未配置，使用默认值100" | tee -a output.txt
	else
		# 显示获取到的值
		echo "S3存储HTTP最大线程数：$value" | tee -a output.txt
	fi


#xray项
elif [ "$machine_type" = "2" ]; then

	echo "主机名: ${cmd1}" | tee -a output.txt
	echo "内核版本: ${cmd2}" | tee -a output.txt
	echo "服务器型号: ${cmd3}" | tee -a output.txt
	echo "系统版本: ${cmd4}" | tee -a output.txt
	echo "系统运行时间: ${cmd5}" | tee -a output.txt
	echo "CPU核数:  ${cmd6}" | tee -a output.txt
	echo "内存： ${cmd7}" | tee -a output.txt
	echo "swap使用: ${cmd8}" | tee -a output.txt
	echo "文件系统空间使用情况:" | tee -a output.txt
	echo "${cmd9}" | tee -a output.txt
	echo "xray版本：$(curl -s -u$user:$passwd -X GET $url/xray/api/v1/system/version | jq -r ".xray_version") " | tee -a output.txt

	if rpm -qa | grep -q xray ; then
		echo "安装类型：使用rpm安装" | tee -a output.txt
	else
		echo "安装类型：使用tar安装" | tee -a output.txt
	fi

	echo "许可证类型及到期时间:" | tee -a output.txt
	echo "${cmd10}" | tee -a output.txt
	echo "GC状态：" | tee -a output.txt
	echo "${cmd11}" | tee -a output.txt
	echo "GC配置：" | tee -a output.txt
	echo "${cmd12}" | tee -a output.txt
	echo "watch配置：" >> output.txt
	echo "${cmd13}" >> output.txt
	echo "polices：" >> output.txt
	echo "${cmd14}" >> output.txt
	echo "忽略规则：" >> output.txt
	echo "${cmd16}" >> output.txt
	echo "violations信息: " >> output.txt
	echo "${cmd15}" >> output.txt
else
    echo "无效的输入"
fi

#dmesg日志
dmesg >>dmesg.log
echo 
echo 
echo "生成的结果文件：$(pwd)/output.txt"
echo "生成的dmesg日志：$(pwd)/dmesg.log"