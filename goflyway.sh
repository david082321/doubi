#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: GoFlyway
#	Version: 1.0.7
#	Author: Toyo
#	Blog: https://doub.io/goflyway-jc2/
#=================================================

sh_ver="1.0.7"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
Folder="/usr/local/goflyway"
File="/usr/local/goflyway/goflyway"
CONF="/usr/local/goflyway/goflyway.conf"
Now_ver_File="/usr/local/goflyway/ver.txt"
Log_File="/usr/local/goflyway/goflyway.log"
Crontab_file="/usr/bin/crontab"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[訊息]${Font_color_suffix}"
Error="${Red_font_prefix}[錯誤]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

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
check_installed_status(){
	[[ ! -e ${File} ]] && echo -e "${Error} GoFlyway 沒有安裝，請檢查 !" && exit 1
}
check_crontab_installed_status(){
	if [[ ! -e ${Crontab_file} ]]; then
		echo -e "${Error} Crontab 沒有安裝，開始安裝..."
		if [[ ${release} == "centos" ]]; then
			yum install crond -y
		else
			apt-get install cron -y
		fi
		if [[ ! -e ${Crontab_file} ]]; then
			echo -e "${Error} Crontab 安裝失敗，請檢查！" && exit 1
		else
			echo -e "${Info} Crontab 安裝成功！"
		fi
	fi
}
check_pid(){
	PID=$(ps -ef| grep "goflyway"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}')
}
check_new_ver(){
	new_ver=$(wget -qO- "https://github.com/coyove/goflyway/tags"|grep "/goflyway/releases/tag/"|grep -v '\-apk'|head -n 1|awk -F "/tag/" '{print $2}'|sed 's/\">//')
	if [[ -z ${new_ver} ]]; then
		echo -e "${Error} GoFlyway 最新版本獲取失敗，請手動獲取最新版本號[ https://github.com/coyove/goflyway/releases ]"
		stty erase '^H' && read -p "請輸入版本號 [ 格式如 v1.1.0a ] :" new_ver
		[[ -z "${new_ver}" ]] && echo "取消..." && exit 1
	else
		echo -e "${Info} 檢測到 GoFlyway 最新版本為 [ ${new_ver} ]"
	fi
}
check_ver_comparison(){
	now_ver=$(cat ${Now_ver_File})
	[[ -z ${now_ver} ]] && echo "${new_ver}" > ${Now_ver_File}
	if [[ ${now_ver} != ${new_ver} ]]; then
		echo -e "${Info} 發現 GoFlyway 已有新版本 [ ${new_ver} ]，目前版本 [ ${now_ver} ]"
		stty erase '^H' && read -p "是否更新 ? [Y/n] :" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			cp "${CONF}" "/tmp/goflyway.conf"
			rm -rf ${Folder}
			mkdir ${Folder}
			Download_goflyway
			mv "/tmp/goflyway.conf" "${CONF}"
			Start_goflyway
		fi
	else
		echo -e "${Info} 目前 GoFlyway 已是最新版本 [ ${new_ver} ]" && exit 1
	fi
}
Download_goflyway(){
	cd ${Folder}
	if [[ ${bit} == "x86_64" ]]; then
		wget --no-check-certificate -N "https://github.com/coyove/goflyway/releases/download/${new_ver}/goflyway_linux_amd64.tar.gz"
		mv goflyway_linux_amd64.tar.gz goflyway_linux.tar.gz
	else
		wget --no-check-certificate -N "https://github.com/coyove/goflyway/releases/download/${new_ver}/goflyway_linux_386.tar.gz"
		mv goflyway_linux_386.tar.gz goflyway_linux.tar.gz
	fi
	[[ ! -e "goflyway_linux.tar.gz" ]] && echo -e "${Error} GoFlyway 下載失敗 !" && exit 1
	tar -xzf goflyway_linux.tar.gz
	[[ ! -e "goflyway" ]] && echo -e "${Error} GoFlyway 解壓失敗 !" && rm -f goflyway_linux.tar.gz && exit 1
	rm -f goflyway_linux.tar.gz
	chmod +x goflyway
	./goflyway -gen-ca
	echo "${new_ver}" > ${Now_ver_File}
}
Service_goflyway(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/david082321/doubi/master/other/goflyway_centos -O /etc/init.d/goflyway; then
			echo -e "${Error} GoFlyway 服務管理腳本下載失敗 !" && exit 1
		fi
		chmod +x /etc/init.d/goflyway
		chkconfig --add goflyway
		chkconfig goflyway on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/david082321/doubi/master/other/goflyway_debian -O /etc/init.d/goflyway; then
			echo -e "${Error} GoFlyway 服務管理腳本下載失敗 !" && exit 1
		fi
		chmod +x /etc/init.d/goflyway
		update-rc.d -f goflyway defaults
	fi
	echo -e "${Info} GoFlyway 服務管理腳本下載完成 !"
}
Installation_dependency(){
	mkdir ${Folder}
}
Write_config(){
	cat > ${CONF}<<-EOF
port=${new_port}
passwd=${new_passwd}
proxy_pass=${new_proxy_pass}
EOF
}
Read_config(){
	[[ ! -e ${CONF} ]] && echo -e "${Error} GoFlyway 設定檔案不存在 !" && exit 1
	port=`cat ${CONF}|grep "port"|awk -F "=" '{print $NF}'`
	passwd=`cat ${CONF}|grep "passwd"|awk -F "=" '{print $NF}'`
	proxy_pass=`cat ${CONF}|grep "proxy_pass"|awk -F "=" '{print $NF}'`
}
Set_port(){
	while true
		do
		echo -e "請輸入 GoFlyway 監聽埠 [1-65535]（如果要偽裝或者套CDN，那麼只能使用埠：80 8080 8880 2052 2082 2086 2095）"
		stty erase '^H' && read -p "(預設: 2333):" new_port
		[[ -z "${new_port}" ]] && new_port="2333"
		expr ${new_port} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${new_port} -ge 1 ]] && [[ ${new_port} -le 65535 ]]; then
				echo && echo "========================"
				echo -e "	埠 : ${Red_background_prefix} ${new_port} ${Font_color_suffix}"
				echo "========================" && echo
				break
			else
				echo "輸入錯誤, 請輸入正確的埠。"
			fi
		else
			echo "輸入錯誤, 請輸入正確的埠。"
		fi
		done
}
Set_passwd(){
	echo "請輸入 GoFlyway 密碼"
	stty erase '^H' && read -p "(預設: doub.io):" new_passwd
	[[ -z "${new_passwd}" ]] && new_passwd="doub.io"
	echo && echo "========================"
	echo -e "	密碼 : ${Red_background_prefix} ${new_passwd} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_proxy_pass(){
	echo "請輸入 GoFlyway 要偽裝的網站(反向代理，只支援 HTTP:// 網站)"
	stty erase '^H' && read -p "(預設不偽裝):" new_proxy_pass
	if [[ ! -z ${new_proxy_pass} ]]; then
		echo && echo "========================"
		echo -e "	偽裝 : ${Red_background_prefix} ${new_proxy_pass} ${Font_color_suffix}"
		echo "========================" && echo
	fi
}
Set_conf(){
	Set_port
	Set_passwd
	Set_proxy_pass
}
Modify_port(){
	Set_port
	Read_config
	new_passwd="${passwd}"
	new_proxy_pass="${proxy_pass}"
	Del_iptables
	Write_config
	Add_iptables
	Save_iptables
	Restart_goflyway
}
Modify_passwd(){
	Set_passwd
	Read_config
	new_port="${port}"
	new_proxy_pass="${proxy_pass}"
	Write_config
	Restart_goflyway
}
Modify_proxy_pass(){
	Set_proxy_pass
	Read_config
	new_port="${port}"
	new_passwd="${passwd}"
	Write_config
	Restart_goflyway
}
Modify_all(){
	Set_conf
	Read_config
	Del_iptables
	Write_config
	Add_iptables
	Save_iptables
	Restart_goflyway
}
Set_goflyway(){
	check_installed_status
	echo && echo -e "你要做什麼？
 ${Green_font_prefix}1.${Font_color_suffix}  修改 埠設定
 ${Green_font_prefix}2.${Font_color_suffix}  修改 密碼設定
 ${Green_font_prefix}3.${Font_color_suffix}  修改 偽裝設定(反向代理)
 ${Green_font_prefix}4.${Font_color_suffix}  修改 全部設定
————————————————
 ${Green_font_prefix}5.${Font_color_suffix}  監控 執行狀態
 
 ${Tip} 使用者的埠是不能重複的，密碼可以重複 !" && echo
	stty erase '^H' && read -p "(預設: 取消):" gf_modify
	[[ -z "${gf_modify}" ]] && echo "已取消..." && exit 1
	if [[ ${gf_modify} == "1" ]]; then
		Modify_port
	elif [[ ${gf_modify} == "2" ]]; then
		Modify_passwd
	elif [[ ${gf_modify} == "3" ]]; then
		Modify_proxy_pass
	elif [[ ${gf_modify} == "4" ]]; then
		Modify_all
	elif [[ ${gf_modify} == "5" ]]; then
		Set_crontab_monitor_goflyway
	else
		echo -e "${Error} 請輸入正確的數位(1-5)" && exit 1
	fi
}
Install_goflyway(){
	[[ -e ${File} ]] && echo -e "${Error} 檢測到 GoFlyway 已安裝 !" && exit 1
	echo -e "${Info} 開始設定 使用者設定..."
	Set_conf
	echo -e "${Info} 開始安裝/設定 依賴..."
	Installation_dependency
	echo -e "${Info} 開始檢測最新版本..."
	check_new_ver
	echo -e "${Info} 開始下載/安裝..."
	Download_goflyway
	echo -e "${Info} 開始下載/安裝 服務腳本(init)..."
	Service_goflyway
	echo -e "${Info} 開始寫入 設定檔案..."
	Write_config
	echo -e "${Info} 開始設定 iptables防火牆..."
	Set_iptables
	echo -e "${Info} 開始添加 iptables防火牆規則..."
	Add_iptables
	echo -e "${Info} 開始儲存 iptables防火牆規則..."
	Save_iptables
	echo -e "${Info} 所有步驟 安裝完畢，開始啟動..."
	Start_goflyway
}
Start_goflyway(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} GoFlyway 正在執行，請檢查 !" && exit 1
	/etc/init.d/goflyway start
	sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View_goflyway
}
Stop_goflyway(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} GoFlyway 沒有執行，請檢查 !" && exit 1
	/etc/init.d/goflyway stop
}
Restart_goflyway(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/goflyway stop
	/etc/init.d/goflyway start
	sleep 1s
	check_pid
	[[ ! -z ${PID} ]] && View_goflyway
}
Update_goflyway(){
	check_installed_status
	check_new_ver
	check_ver_comparison
}
Uninstall_goflyway(){
	check_installed_status
	echo "確定要移除 GoFlyway ? (y/N)"
	echo
	stty erase '^H' && read -p "(預設: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config
		Del_iptables
		rm -rf ${Folder}
		if [[ ${release} = "centos" ]]; then
			chkconfig --del goflyway
		else
			update-rc.d -f goflyway remove
		fi
		rm -rf /etc/init.d/goflyway
		echo && echo "GoFlyway 移除完成 !" && echo
	else
		echo && echo "移除已取消..." && echo
	fi
}
View_goflyway(){
	check_installed_status
	Read_config
	ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ip}" ]]; then
		ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ip}" ]]; then
				ip="VPS_IP"
			fi
		fi
	fi
	[[ -z ${proxy_pass} ]] && proxy_pass="無"
	link_qr
	clear && echo "————————————————" && echo
	echo -e " GoFlyway 訊息 :" && echo
	echo -e " 地址\t: ${Green_font_prefix}${ip}${Font_color_suffix}"
	echo -e " 埠\t: ${Green_font_prefix}${port}${Font_color_suffix}"
	echo -e " 密碼\t: ${Green_font_prefix}${passwd}${Font_color_suffix}"
	echo -e " 偽裝\t: ${Green_font_prefix}${proxy_pass}${Font_color_suffix}"
	echo -e "${link}"
	echo -e "${Tip} 連結僅適用於Windows系統的 Goflyway Tools 使用者端（https://doub.io/dbrj-11/）。"
	echo && echo "————————————————"
}
urlsafe_base64(){
	date=$(echo -n "$1"|base64|sed ':a;N;s/\n//g;ta'|sed 's/=//g;s/+/-/g;s/\//_/g')
	echo -e "${date}"
}
link_qr(){
	PWDbase64=$(urlsafe_base64 "${passwd}")
	base64=$(urlsafe_base64 "${ip}:${port}:${PWDbase64}")
	url="goflyway://${base64}"
	QRcode="http://doub.pw/qr/qr.php?text=${url}"
	link=" 連結\t: ${Red_font_prefix}${url}${Font_color_suffix} \n 二維碼 : ${Red_font_prefix}${QRcode}${Font_color_suffix} \n "
}
View_Log(){
	check_installed_status
	[[ ! -e ${Log_File} ]] && echo -e "${Error} GoFlyway 日誌檔案不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 終止查看日誌" && echo
	tail -f ${Log_File}
}
# 顯示 連接訊息
debian_View_user_connection_info(){
	format_1=$1
	Read_config
	user_port=${port}
	user_IP_1=$(netstat -anp |grep 'ESTABLISHED' |grep 'goflyway' |grep 'tcp6' |grep ":${user_port} " |awk '{print $5}' |awk -F ":" '{print $1}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
	if [[ -z ${user_IP_1} ]]; then
		user_IP_total="0"
		echo -e "埠: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 連結IP總數: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 目前連結IP: "
	else
		user_IP_total=`echo -e "${user_IP_1}"|wc -l`
		if [[ ${format_1} == "IP_address" ]]; then
			echo -e "埠: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 連結IP總數: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 目前連結IP: "
			get_IP_address
			echo
		else
			user_IP=$(echo -e "\n${user_IP_1}")
			echo -e "埠: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 連結IP總數: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 目前連結IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
		fi
	fi
	user_IP=""
}
centos_View_user_connection_info(){
	format_1=$1
	Read_config
	user_port=${port}
	user_IP_1=`netstat -anp |grep 'ESTABLISHED' |grep 'goflyway' |grep 'tcp' |grep ":${user_port} "|grep '::ffff:' |awk '{print $5}' |awk -F ":" '{print $4}' |sort -u |grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"`
	if [[ -z ${user_IP_1} ]]; then
		user_IP_total="0"
		echo -e "埠: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 連結IP總數: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 目前連結IP: "
	else
		user_IP_total=`echo -e "${user_IP_1}"|wc -l`
		if [[ ${format_1} == "IP_address" ]]; then
			echo -e "埠: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 連結IP總數: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 目前連結IP: "
			get_IP_address
			echo
		else
			user_IP=$(echo -e "\n${user_IP_1}")
			echo -e "埠: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 連結IP總數: ${Green_font_prefix}"${user_IP_total}"${Font_color_suffix}\t 目前連結IP: ${Green_font_prefix}${user_IP}${Font_color_suffix}\n"
		fi
	fi
	user_IP=""
}
View_user_connection_info(){
	check_installed_status
	echo && echo -e "請選擇要顯示的格式：
 ${Green_font_prefix}1.${Font_color_suffix} 顯示 IP 格式
 ${Green_font_prefix}2.${Font_color_suffix} 顯示 IP+IP歸屬地 格式" && echo
	stty erase '^H' && read -p "(預設: 1):" goflyway_connection_info
	[[ -z "${goflyway_connection_info}" ]] && goflyway_connection_info="1"
	if [[ "${goflyway_connection_info}" == "1" ]]; then
		View_user_connection_info_1 ""
	elif [[ "${goflyway_connection_info}" == "2" ]]; then
		echo -e "${Tip} 檢測IP歸屬地(ipip.net)，如果IP較多，可能時間會比較長..."
		View_user_connection_info_1 "IP_address"
	else
		echo -e "${Error} 請輸入正確的數位(1-2)" && exit 1
	fi
}
View_user_connection_info_1(){
	format=$1
	if [[ ${release} = "centos" ]]; then
		cat /etc/redhat-release |grep 7\..*|grep -i centos>/dev/null
		if [[ $? = 0 ]]; then
			debian_View_user_connection_info "$format"
		else
			centos_View_user_connection_info "$format"
		fi
	else
		debian_View_user_connection_info "$format"
	fi
}
get_IP_address(){
	#echo "user_IP_1=${user_IP_1}"
	if [[ ! -z ${user_IP_1} ]]; then
	#echo "user_IP_total=${user_IP_total}"
		for((integer_1 = ${user_IP_total}; integer_1 >= 1; integer_1--))
		do
			IP=$(echo "${user_IP_1}" |sed -n "$integer_1"p)
			#echo "IP=${IP}"
			IP_address=$(wget -qO- -t1 -T2 http://freeapi.ipip.net/${IP}|sed 's/\"//g;s/,//g;s/\[//g;s/\]//g')
			#echo "IP_address=${IP_address}"
			#user_IP="${user_IP}\n${IP}(${IP_address})"
			echo -e "${Green_font_prefix}${IP}${Font_color_suffix} (${IP_address})"
			#echo "user_IP=${user_IP}"
			sleep 1s
		done
	fi
}
Set_crontab_monitor_goflyway(){
	check_crontab_installed_status
	crontab_monitor_goflyway_status=$(crontab -l|grep "goflyway.sh monitor")
	if [[ -z "${crontab_monitor_goflyway_status}" ]]; then
		echo && echo -e "目前監控模式: ${Green_font_prefix}未開啟${Font_color_suffix}" && echo
		echo -e "確定要開啟 ${Green_font_prefix}Goflyway 服務端執行狀態監控${Font_color_suffix} 功能嗎？(當進程關閉則自動啟動SSR服務端)[Y/n]"
		stty erase '^H' && read -p "(預設: y):" crontab_monitor_goflyway_status_ny
		[[ -z "${crontab_monitor_goflyway_status_ny}" ]] && crontab_monitor_goflyway_status_ny="y"
		if [[ ${crontab_monitor_goflyway_status_ny} == [Yy] ]]; then
			crontab_monitor_goflyway_cron_start
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo && echo -e "目前監控模式: ${Green_font_prefix}已開啟${Font_color_suffix}" && echo
		echo -e "確定要關閉 ${Green_font_prefix}Goflyway 服務端執行狀態監控${Font_color_suffix} 功能嗎？(當進程關閉則自動啟動SSR服務端)[y/N]"
		stty erase '^H' && read -p "(預設: n):" crontab_monitor_goflyway_status_ny
		[[ -z "${crontab_monitor_goflyway_status_ny}" ]] && crontab_monitor_goflyway_status_ny="n"
		if [[ ${crontab_monitor_goflyway_status_ny} == [Yy] ]]; then
			crontab_monitor_goflyway_cron_stop
		else
			echo && echo "	已取消..." && echo
		fi
	fi
}
crontab_monitor_goflyway_cron_start(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/goflyway.sh monitor/d" "$file_1/crontab.bak"
	echo -e "\n* * * * * /bin/bash $file_1/goflyway.sh monitor" >> "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "goflyway.sh monitor")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} Goflyway 服務端執行狀態監控功能 啟動失敗 !" && exit 1
	else
		echo -e "${Info} Goflyway 服務端執行狀態監控功能 啟動成功 !"
	fi
}
crontab_monitor_goflyway_cron_stop(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/goflyway.sh monitor/d" "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -r "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "goflyway.sh monitor")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} Goflyway 服務端執行狀態監控功能 停止失敗 !" && exit 1
	else
		echo -e "${Info} Goflyway 服務端執行狀態監控功能 停止成功 !"
	fi
}
crontab_monitor_goflyway(){
	check_installed_status
	check_pid
	echo "${PID}"
	if [[ -z ${PID} ]]; then
		echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] 檢測到 Goflyway服務端 未執行 , 開始啟動..." | tee -a ${Log_File}
		/etc/init.d/goflyway start
		sleep 1s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Goflyway服務端 啟動失敗..." | tee -a ${Log_File}
		else
			echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Goflyway服務端 啟動成功..." | tee -a ${Log_File}
		fi
	else
		echo -e "${Info} [$(date "+%Y-%m-%d %H:%M:%S %u %Z")] Goflyway服務端 進程執行正常..." | tee -a ${Log_File}
	fi
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${new_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${new_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		chkconfig --level 2345 iptables on
	else
		iptables-save > /etc/iptables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
Update_Shell(){
	echo -e "目前版本為 [ ${sh_ver} ]，開始檢測最新版本..."
	sh_new_ver=$(wget --no-check-certificate -qO- "https://softs.loan/Bash/goflyway.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="softs"
	[[ -z ${sh_new_ver} ]] && sh_new_ver=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/david082321/doubi/master/goflyway.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 檢測最新版本失敗 !" && exit 0
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "發現新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
		stty erase '^H' && read -p "(預設: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			if [[ $sh_new_type == "softs" ]]; then
				wget -N --no-check-certificate https://softs.loan/Bash/goflyway.sh && chmod +x goflyway.sh
			else
				wget -N --no-check-certificate https://raw.githubusercontent.com/david082321/doubi/master/goflyway.sh && chmod +x goflyway.sh
			fi
			echo -e "腳本已更新為最新版本[ ${sh_new_ver} ] !"
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo -e "目前已是最新版本[ ${sh_new_ver} ] !"
	fi
}
check_sys
action=$1
if [[ "${action}" == "monitor" ]]; then
	crontab_monitor_goflyway
else
echo && echo -e "  GoFlyway 一鍵管理腳本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/goflyway-jc2 --
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升級腳本
————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安裝 GoFlyway
 ${Green_font_prefix} 2.${Font_color_suffix} 升級 GoFlyway
 ${Green_font_prefix} 3.${Font_color_suffix} 移除 GoFlyway
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 啟動 GoFlyway
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 GoFlyway
 ${Green_font_prefix} 6.${Font_color_suffix} 重啟 GoFlyway
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 設定 帳號設定
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 帳號訊息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 日誌訊息
 ${Green_font_prefix}10.${Font_color_suffix} 查看 連結訊息
————————————" && echo
if [[ -e ${File} ]]; then
	check_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e " 目前狀態: ${Green_font_prefix}已安裝${Font_color_suffix} 並 ${Green_font_prefix}已啟動${Font_color_suffix}"
	else
		echo -e " 目前狀態: ${Green_font_prefix}已安裝${Font_color_suffix} 但 ${Red_font_prefix}未啟動${Font_color_suffix}"
	fi
else
	echo -e " 目前狀態: ${Red_font_prefix}未安裝${Font_color_suffix}"
fi
echo
stty erase '^H' && read -p " 請輸入數字 [0-10]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_goflyway
	;;
	2)
	Update_goflyway
	;;
	3)
	Uninstall_goflyway
	;;
	4)
	Start_goflyway
	;;
	5)
	Stop_goflyway
	;;
	6)
	Restart_goflyway
	;;
	7)
	Set_goflyway
	;;
	8)
	View_goflyway
	;;
	9)
	View_Log
	;;
	10)
	View_user_connection_info
	;;
	*)
	echo "請輸入正確數字 [0-10]"
	;;
esac
fi
