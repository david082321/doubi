#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Peerflix Server
#	Version: 1.0.3
#	Author: Toyo
#	Blog: https://doub.io/wlzy-13/
#=================================================

node_ver="v6.9.1"
node_file="/etc/node"
ps_file="/etc/node/lib/node_modules/peerflix-server"

#檢查系統
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
deliptables(){
	port_total=`netstat -lntp | grep node | awk '{print $4}' | awk -F ":" '{print $4}' | wc -l`
	for((integer = 1; integer <= ${port_total}; integer++))
	do
		port=`netstat -lntp | grep node | awk '{print $4}' | awk -F ":" '{print $4}' | sed -n "${integer}p"`
		if [ ${port} != "" ]; then
			iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
			iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
		fi
	done
	iptables -D OUTPUT -m state --state NEW -m tcp -p tcp --dport 6881 -j ACCEPT
	iptables -D OUTPUT -m state --state NEW -m udp -p udp --dport 6881 -j ACCEPT
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport 6881 -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport 6881 -j ACCEPT
}
# 安裝PS
installps(){
# 判斷是否安裝PS
	if [ -e ${ps_file} ];
	then
		echo -e "\033[41;37m [錯誤] \033[0m 檢測到 Peerflix Server 已安裝，如需繼續，請先移除 !"
		exit 1
	fi

	check_sys
# 系統判斷
	if [ ${release} == "centos" ]; then
		yum update
		yum install -y build-essential curl vim xz tar
	elif [ ${release} == "debian" ]; then
		apt-get update
		apt-get install -y build-essential curl vim xz tar
	elif [ ${release} == "ubuntu" ]; then
		sudo apt-get update
		sudo apt-get install -y build-essential curl vim xz tar
	else
		echo -e "\033[41;37m [錯誤] \033[0m 本腳本不支援目前系統 !"
		exit 1
	fi
	
	#修改DNS為8.8.8.8
	echo "nameserver 8.8.8.8" > /etc/resolv.conf
	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
	
	if [ ${bit} == "x86_64" ]; then
		wget -N -O node.tar.xz "https://nodejs.org/dist/v6.9.1/node-v6.9.1-linux-x64.tar.xz"
		xz -d node.tar.xz
		tar -xvf node.tar -C "/etc"
		mv /etc/node-v6.9.1-linux-x64 ${node_file}
		rm -rf node.tar
		ln -s ${node_file}/bin/node /usr/local/bin/node
		ln -s ${node_file}/bin/npm /usr/local/bin/npm
	elif [ ${bit} == "i386" ]; then
		wget -N -O node.tar.xz "https://nodejs.org/dist/v6.9.1/node-v6.9.1-linux-x86.tar.xz"
		xz -d node.tar.xz
		tar -xvf node.tar -C "/etc"
		mv /etc/node-v6.9.1-linux-x86 ${node_file}
		rm -rf node.tar
		ln -s ${node_file}/bin/node /usr/local/bin/node
		ln -s ${node_file}/bin/npm /usr/local/bin/npm
	else
		echo -e "\033[41;37m [錯誤] \033[0m 不支援 ${bit} !"
		exit 1
	fi
	
	npm install -g peerflix-server
	
# 判斷是否下載成功
	if [ ! -e ${ps_file} ]; then
		echo -e "\033[41;37m [錯誤] \033[0m Peerflix Server 安裝失敗 !"
		exit 1
	fi
	startps
}
startps(){
# 檢查是否安裝
	if [ ! -e ${ps_file} ]; then
		echo -e "\033[41;37m [錯誤] \033[0m Peerflix Server 沒有安裝，請檢查 !"
		exit 1
	fi
# 判斷進程是否存在
	PID=`ps -ef | grep peerflix-server | grep -v grep | awk '{print $2}'`
	if [ ! -z $PID ]; then
		echo -e "\033[41;37m [錯誤] \033[0m Peerflix Server 進程正在執行，請檢查 !"
		exit 1
	fi
	
	#設定埠
	while true
	do
	echo -e "請輸入 Peerflix Server 監聽埠 [1-65535]"
	stty erase '^H' && read -p "(預設埠: 9000):" PORT
	[ -z "$PORT" ] && PORT="9000"
	expr ${PORT} + 0 &>/dev/null
	if [ $? -eq 0 ]; then
		if [ ${PORT} -ge 1 ] && [ ${PORT} -le 65535 ]; then
			echo
			echo "——————————————————————————————"
			echo -e "	埠 : \033[41;37m ${PORT} \033[0m"
			echo "——————————————————————————————"
			echo
			break
		else
			echo "輸入錯誤，請輸入正確的數位 !"
		fi
	else
		echo "輸入錯誤，請輸入正確的數位 !"
	fi
	done
	
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${PORT} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${PORT} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 6881 -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport 6881 -j ACCEPT
	iptables -I OUTPUT -m state --state NEW -m tcp -p tcp --dport 6881 -j ACCEPT
	iptables -I OUTPUT -m state --state NEW -m udp -p udp --dport 6881 -j ACCEPT

	PORT=${PORT} nohup node ${ps_file}>> ${ps_file}/peerflixs.log 2>&1 &
	
	sleep 2s
	# 判斷進程是否存在
	PID=`ps -ef | grep peerflix-server | grep -v grep | awk '{print $2}'`
	if [ -z $PID ]; then
		echo
		echo -e "\033[41;37m [錯誤] \033[0m Peerflix Server 啟動失敗 !"
		exit 1
	fi
	# 獲取IP
	ip=`curl -m 10 -s http://members.3322.org/dyndns/getip`
	if [ -z $ip ]; then
		ip="ip"
	fi
	echo
	echo "Peerflix Server 已啟動 !"
	echo -e "瀏覽器訪問，地址： \033[41;37m http://${ip}:${PORT} \033[0m "
	echo
}
stopps(){
# 判斷進程是否存在
	PID=`ps -ef | grep peerflix-server | grep -v grep | awk '{print $2}'`
	if [ -z $PID ]; then
		echo -e "\033[41;37m [錯誤] \033[0m 沒有發現 Peerflix Server 進程執行，請檢查 !"
		exit 1
	fi
	deliptables
	kill -9 ${PID}
	sleep 2s
	PID=`ps -ef | grep peerflix-server | grep -v grep | awk '{print $2}'`
	if [ ! -z $PID ];
	then
		echo -e "\033[41;37m [錯誤] \033[0m Peerflix Server 停止失敗 !"
		exit 1
	else
		echo
		echo "Peerflix Server 已停止 !"
		echo
	fi
}
# 查看日誌
tailps(){
# 判斷日誌是否存在
	if [ ! -e ${ps_file}/peerflixs.log ];
	then
		echo -e "\033[41;37m [錯誤] \033[0m Peerflix Server 日誌檔案不存在 !"
		exit 1
	else
		tail -f ${ps_file}/peerflixs.log
	fi
}
autops(){
	if [ ! -e ${ps_file} ]; then
		echo -e "\033[41;37m [錯誤] \033[0m Peerflix Server 沒有安裝，開始安裝 !"
		installps
	else
		PID=`ps -ef | grep peerflix-server | grep -v grep | awk '{print $2}'`
		if [ -z $PID ];
		then
			echo -e "\033[41;37m [錯誤] \033[0m Peerflix Server 沒有啟動，開始啟動 !"
			startps
		else
			printf "Peerflix Server 正在執行，是否停止 ? (y/N)"
			printf "\n"
			stty erase '^H' && read -p "(預設: n):" autoyn
			[ -z ${autoyn} ] && autoyn="n"
			if [[ ${autoyn} == [Yy] ]]; then
				stopps
			fi
		fi
	fi
}
uninstallps(){
# 檢查是否安裝
	if [ ! -e ${ps_file} ]; then
		echo -e "\033[41;37m [錯誤] \033[0m Peerflix Server 沒有安裝，請檢查 !"
		exit 1
	fi

	printf "確定要移除 Peerflix Server ? (y/N)"
	printf "\n"
	stty erase '^H' && read -p "(預設: n):" unyn
	[ -z ${unyn} ] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		PID=`ps -ef | grep peerflix-server | grep -v grep | awk '{print $2}'`
		if [ ! -z $PID ]; then
			deliptables
			kill -9 ${PID}
		fi
		rm -rf /usr/local/bin/node
		rm -rf /usr/local/bin/npm
		rm -rf ${node_file}
		echo
		echo "Peerflix Server 移除完成 !"
		echo
	else
		echo
		echo "移除已取消..."
		echo
	fi
}

action=$1
[ -z $1 ] && action=auto
case "$action" in
	auto|install|start|stop|tail|uninstall)
	${action}ps
	;;
	*)
	echo "輸入錯誤 !"
	echo "用法: {install | start | stop | tail | uninstall}"
	;;
esac
