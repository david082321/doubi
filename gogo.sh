#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/java/jre/bin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: GoGo Server
#	Version: 1.0.0
#	Author: Toyo
#	Blog: https://doub.io/wlzy-24/
#=================================================

gogo_directory="/etc/gogoserver"
gogo_file="/etc/gogoserver/gogo-server.jar"
java_directory="/usr/java"
java_file="/usr/java/jre"
profile_file="/etc/profile"
httpsport="8443"

#檢查是否安裝gogo
check_gogo(){
	[[ ! -e ${gogo_file} ]] && echo -e "\033[41;37m [錯誤] \033[0m 沒有安裝GoGo，請檢查 !" && exit 1
}
#檢查是否安裝java
check_java(){
	java_check=`java -version`
	[[ -z ${java_check} ]] && echo -e "\033[41;37m [錯誤] \033[0m 沒有安裝JAVA，請檢查 !" && exit 1
}
#檢查系統
check_sys(){
	bit=`uname -m`
}
# 安裝java
installjava(){
	mkdir ${java_directory}
	cd ${java_directory}
	check_sys
# 系統判斷
	if [ ${bit} == "x86_64" ]; then
		wget -N -O java.tar.gz "http://javadl.oracle.com/webapps/download/AutoDL?BundleId=216424"
	elif [ ${bit} == "i386" ]; then
		wget -N -O java.tar.gz "http://javadl.oracle.com/webapps/download/AutoDL?BundleId=216422"
	else
		echo -e "\033[41;37m [錯誤] \033[0m 不支援 ${bit} !" && exit 1
	fi
	tar zxvf java.tar.gz
	jre_file=`ls -a | grep 'jre'`
	mv ${jre_file} jre
	rm -rf java.tar.gz
# 設定java環境變數
	echo '#set java JDK 
JAVA_HOME=/usr/java/jre
JRE_HOME=/usr/java/jre/jre/ 
PATH=$PATH:$JAVA_HOME/bin:$JRE_home/bin 
CLASSPATH=$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar 
export JAVA_HOME 
export JRE_HOME 
export PATH 
export CLASSPATH' >> ${profile_file}
	source ${profile_file}
#判斷java是否安裝成功
	#java_check=`java -version`
	#[[ -z ${java_check} ]] && echo -e "\033[41;37m [錯誤] \033[0m 安裝 JAVA 失敗，請檢查 !" && exit 1
}
# 安裝gogo
installgogo(){
# 判斷是否安裝gogo
	[[ -e ${gogo_file} ]] && echo -e "\033[41;37m [錯誤] \033[0m 已經安裝 GoGo，請檢查 !" && exit 1
# 判斷是否安裝java
	#java_check=`java -version`
	if [[ ! -e ${java_directory} ]]; then
		echo -e "\033[42;37m [訊息] \033[0m 沒有檢測到安裝 JAVA，開始安裝..."
		installjava
	fi
	chmod +x /etc/rc.local
	mkdir ${gogo_directory}
	cd ${gogo_directory}
	wget -N -O gogo-server.jar --no-check-certificate "https://gogohome.herokuapp.com/getLatestGoGoServer"
	#判斷gogo是否下載成功
	if [[ ! -e ${gogo_file} ]]; then
		echo -e "\033[41;37m [錯誤] \033[0m 下載GoGo失敗，請檢查 !" && exit 1
	else
		startgogo
	fi
}
setgogo(){
#設定埠
	while true
	do
	echo -e "請輸入GoGo Server 的 HTTP監聽埠 [1-65535]:"
	stty erase '^H' && read -p "(預設埠: 8080):" httpport
	[ -z "$httpport" ] && httpport="8080"
	expr ${httpport} + 0 &>/dev/null
	if [ $? -eq 0 ]; then
		if [ ${httpport} -ge 1 ] && [ ${httpport} -le 65535 ]; then
			echo
			echo "——————————————————————————————"
			echo -e "	埠 : \033[41;37m ${httpport} \033[0m"
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
}
# 查看gogo列表
viewgogo(){
# 檢查是否安裝
	check_gogo
	
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	[[ -z $PID ]] && echo -e "\033[42;37m [訊息] \033[0m GoGo 沒有執行 !" && exit 1
	
	gogo_http_port=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $12}'`
# 獲取IP
	ip=`curl -m 10 -s http://members.3322.org/dyndns/getip`
	[[ -z $ip ]] && ip="vps_ip"
	echo
	echo "——————————————————————————————"
	echo "	GoGo Server 設定訊息: "
	echo
	echo -e "	本機 IP : \033[41;37m ${ip} \033[0m"
	echo -e "	HTTP監聽埠 : \033[41;37m ${gogo_http_port} \033[0m"
	echo -e "	HTTPS監聽埠 : \033[41;37m ${httpsport} \033[0m"
	echo "——————————————————————————————"
	echo
}
# 啟動aProxy
startgogo(){
# 檢查是否安裝
	check_gogo
# 判斷進程是否存在
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	[[ ! -z $PID ]] && echo -e "\033[41;37m [錯誤] \033[0m 發現 GoGo 正在執行，請檢查 !" && exit 1
	cd ${gogo_directory}
	setgogo
	nohup java -Xmx300m -jar gogo-server.jar ${httpport} &>/dev/null &
	sleep 2s
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	[[ -z $PID ]] && echo -e "\033[41;37m [錯誤] \033[0m GoGo 啟動失敗 !" && exit 1
	iptables -I INPUT -p tcp --dport ${httpport} -j ACCEPT
	iptables -I INPUT -p udp --dport ${httpport} -j ACCEPT
	iptables -I INPUT -p tcp --dport ${httpsport} -j ACCEPT
	iptables -I INPUT -p udp --dport ${httpsport} -j ACCEPT
# 系統判斷,開機啟動
	check_sys
	if [[ ${release}  == "debian" ]]; then
		sed -i '$d' /etc/rc.local
		echo -e "nohup java -Xmx300m -jar gogo-server.jar ${httpport} &>/dev/null &" >> /etc/rc.local
		echo -e "exit 0" >> /etc/rc.local
	else
		echo -e "nohup java -Xmx300m -jar gogo-server.jar ${httpport} &>/dev/null &" >> /etc/rc.local
	fi
	
	clear
	echo
	echo "——————————————————————————————"
	echo
	echo "	GoGo 已啟動 !"
	viewgogo
}
# 停止aProxy
stopgogo(){
# 檢查是否安裝
	check_gogo
# 判斷進程是否存在
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	[[ -z $PID ]] && echo -e "\033[41;37m [錯誤] \033[0m 發現 GoGo 沒有執行，請檢查 !" && exit 1
	gogo_http_port=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $12}'`
	sed -i "/nohup java -Xmx300m -jar gogo-server.jar ${gogo_http_port} &>\/dev\/null &/d" /etc/rc.local
	iptables -D INPUT -p tcp --dport ${gogo_http_port} -j ACCEPT
	iptables -D INPUT -p udp --dport ${gogo_http_port} -j ACCEPT
	iptables -D INPUT -p tcp --dport ${httpsport} -j ACCEPT
	iptables -D INPUT -p udp --dport ${httpsport} -j ACCEPT
	kill -9 ${PID}
	sleep 2s
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	if [[ ! -z $PID ]]; then
		echo -e "\033[41;37m [錯誤] \033[0m GoGo 停止失敗 !" && exit 1
	else
		echo "	GoGo 已停止 !"
	fi
}
restartgogo(){
# 檢查是否安裝
	check_gogo
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	[[ ! -z $PID ]] && stopgogo
	startgogo
}
statusgogo(){
# 檢查是否安裝
	check_gogo
# 判斷進程是否存在
	PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
	if [[ ! -z $PID ]]; then
		echo -e "\033[42;37m [訊息] \033[0m GoGo 正在執行，PID: ${PID} !"
	else
		echo -e "\033[42;37m [訊息] \033[0m GoGo 沒有執行 !"
	fi
}
uninstallgogo(){
# 檢查是否安裝
	check_gogo
	printf "確定要移除 GoGo ? (y/N)"
	printf "\n"
	stty erase '^H' && read -p "(預設: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		PID=`ps -ef | grep "gogo" | grep -v grep | grep -v "gogo.sh" | awk '{print $2}'`
		[[ ! -z $PID ]] && stopgogo
		rm -rf ${gogo_directory}
		sed -i "/nohup java -Xmx300m -jar gogo-server.jar ${gogo_http_port} &>\/dev\/null &/d" /etc/rc.local
		[[ -e ${gogo_directory} ]] && echo -e "\033[41;37m [錯誤] \033[0m GoGo移除失敗，請檢查 !" && exit 1
		echo
		echo "	GoGo 已移除 !"
		echo
	else
		echo
		echo "移除已取消..."
		echo
	fi
}

action=$1
[[ -z $1 ]] && action=install
case "$action" in
	install|view|start|stop|restart|status|uninstall)
	${action}gogo
	;;
	*)
	echo "輸入錯誤 !"
	echo "用法: { install | view | start | stop | restart | status | uninstall }"
	;;
esac
