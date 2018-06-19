#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#       System Required: All
#       Description: Python HTTP Server
#       Version: 1.0.2
#       Author: Toyo
#       Blog: https://doub.io/wlzy-8/
#=================================================

sethttp(){
#設定埠
	while true
	do
	echo -e "請輸入要開放的HTTP服務埠 [1-65535]"
	stty erase '^H' && read -p "(預設埠: 8000):" httpport
	[[ -z "$httpport" ]] && httpport="8000"
	expr ${httpport} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${httpport} -ge 1 ]] && [[ ${httpport} -le 65535 ]]; then
			echo
			echo -e "	埠 : \033[41;37m ${httpport} \033[0m"
			echo
			break
		else
			echo "輸入錯誤, 請輸入正確的埠。"
		fi
	else
		echo "輸入錯誤, 請輸入正確的埠。"
	fi
	done
	#設定目錄
	echo "請輸入要開放的目錄(絕對路徑)"
	stty erase '^H' && read -p "(直接回車, 預設目前資料夾):" httpfile
	if [[ ! -z $httpfile ]]; then
		[[ ! -e $httpfile ]] && echo -e "\033[41;37m [錯誤] \033[0m 輸入的目錄不存在 或 目前使用者無權限訪問, 請檢查!" && exit 1
	else
		httpfile=`echo $PWD`
	fi
	#最後確認
	echo
	echo "========================"
	echo "      請檢查設定是否正確 !"
	echo
	echo -e "	埠 : \033[41;37m ${httpport} \033[0m"
	echo -e "	目錄 : \033[41;37m ${httpfile} \033[0m"
	echo "========================"
	echo
	stty erase '^H' && read -p "按任意鍵繼續，如有錯誤，請使用 Ctrl + C 退出." var
}
iptables_add(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${httpport} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${httpport} -j ACCEPT
}
iptables_del(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}
starthttp(){
	PID=`ps -ef | grep SimpleHTTPServer | grep -v grep | awk '{print $2}'`
	[[ ! -z $PID ]] && echo -e "\033[41;37m [錯誤] \033[0m SimpleHTTPServer 正著執行，請檢查 !" && exit 1
	sethttp
	iptables_add
	cd ${httpfile}
	nohup python -m SimpleHTTPServer $httpport >> httpserver.log 2>&1 &
	sleep 2s
	PID=`ps -ef | grep SimpleHTTPServer | grep -v grep | awk '{print $2}'`
	if [[ -z $PID ]]; then
		echo -e "\033[41;37m [錯誤] \033[0m SimpleHTTPServer 啟動失敗 !" && exit 1
	else
		ip=`curl -m 10 -s http://members.3322.org/dyndns/getip`
		[[ -z "$ip" ]] && ip="VPS_IP"
		echo
		echo "HTTP服務 已啟動 !"
		echo -e "瀏覽器訪問，地址： \033[41;37m http://${ip}:${httpport} \033[0m "
		echo
	fi
}
stophttp(){
	PID=`ps -ef | grep SimpleHTTPServer | grep -v grep | awk '{print $2}'`
	[[ -z $PID ]] && echo -e "\033[41;37m [錯誤] \033[0m 沒有發現 SimpleHTTPServer 進程執行，請檢查 !" && exit 1
	port=`netstat -lntp | grep ${PID} | awk '{print $4}' | awk -F ":" '{print $2}'`
	iptables_del
	kill -9 ${PID}
	sleep 2s
	PID=`ps -ef | grep SimpleHTTPServer | grep -v grep | awk '{print $2}'`
	if [[ ! -z $PID ]]; then
		echo -e "\033[41;37m [錯誤] \033[0m SimpleHTTPServer 停止失敗 !" && exit 1
	else
		echo
		echo "HTTP服務 已停止 !"
		echo
	fi
}

action=$1
[[ -z $1 ]] && action=start
case "$action" in
    start|stop)
    ${action}http
    ;;
    *)
    echo "輸入錯誤 !"
    echo "用法: {start|stop}"
    ;;
esac
