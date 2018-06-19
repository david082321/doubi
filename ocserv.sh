#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: Debian/Ubuntu
#	Description: ocserv AnyConnect
#	Version: 1.0.3
#	Author: Toyo
#	Blog: https://doub.io/vpnzy-7/
#=================================================
sh_ver="1.0.3"
file="/usr/local/sbin/ocserv"
conf_file="/etc/ocserv"
conf="/etc/ocserv/ocserv.conf"
passwd_file="/etc/ocserv/ocpasswd"
log_file="/tmp/ocserv.log"
ocserv_ver="0.11.8"
PID_FILE="/var/run/ocserv.pid"

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
	#bit=`uname -m`
}
check_installed_status(){
	[[ ! -e ${file} ]] && echo -e "${Error} ocserv 沒有安裝，請檢查 !" && exit 1
	[[ ! -e ${conf} ]] && echo -e "${Error} ocserv 設定檔案不存在，請檢查 !" && [[ $1 != "un" ]] && exit 1
}
check_pid(){
	if [[ ! -e ${PID_FILE} ]]; then
		PID=""
	else
		PID=$(cat ${PID_FILE})
	fi
}
Get_ip(){
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
}
Download_ocserv(){
	mkdir "ocserv" && cd "ocserv"
	wget "ftp://ftp.infradead.org/pub/ocserv/ocserv-${ocserv_ver}.tar.xz"
	[[ ! -s "ocserv-${ocserv_ver}.tar.xz" ]] && echo -e "${Error} ocserv 原始碼檔案下載失敗 !" && rm -rf "ocserv/" && rm -rf "ocserv-${ocserv_ver}.tar.xz" && exit 1
	tar -xJf ocserv-0.11.8.tar.xz && cd ocserv-0.11.8
	./configure
	make
	make install
	cd .. && cd ..
	rm -rf ocserv/
	
	if [[ -e ${file} ]]; then
		mkdir "${conf_file}"
		wget --no-check-certificate -N -P "${conf_file}" "https://raw.githubusercontent.com/david082321/doubi/master/other/ocserv.conf"
		[[ ! -s "${conf}" ]] && echo -e "${Error} ocserv 設定檔案下載失敗 !" && rm -rf "${conf_file}" && exit 1
	else
		echo -e "${Error} ocserv 編譯安裝失敗，請檢查！" && exit 1
	fi
}
Service_ocserv(){
	if ! wget --no-check-certificate https://raw.githubusercontent.com/david082321/doubi/master/other/ocserv_debian -O /etc/init.d/ocserv; then
		echo -e "${Error} ocserv 服務 管理腳本下載失敗 !" && over
	fi
	chmod +x /etc/init.d/ocserv
	update-rc.d -f ocserv defaults
	echo -e "${Info} ocserv 服務 管理腳本下載完成 !"
}
rand(){
	min=10000
	max=$((60000-$min+1))
	num=$(date +%s%N)
	echo $(($num%$max+$min))
}
Generate_SSL(){
	lalala=$(rand)
	mkdir /tmp/ssl && cd /tmp/ssl
	echo -e 'cn = "'${lalala}'"
organization = "'${lalala}'"
serial = 1
expiration_days = 365
ca
signing_key
cert_signing_key
crl_signing_key' > ca.tmpl
	[[ $? != 0 ]] && echo -e "${Error} 寫入SSL證書籤名模板失敗(ca.tmpl) !" && over
	certtool --generate-privkey --outfile ca-key.pem
	[[ $? != 0 ]] && echo -e "${Error} 生成SSL證書密匙檔案失敗(ca-key.pem) !" && over
	certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem
	[[ $? != 0 ]] && echo -e "${Error} 生成SSL證書檔案失敗(ca-cert.pem) !" && over
	
	Get_ip
	if [[ -z "$ip" ]]; then
		echo -e "${Error} 檢測外網IP失敗 !"
		stty erase '^H' && read -p "請手動輸入你的伺服器外網IP:" ip
		[[ -z "${ip}" ]] && echo "取消..." && over
	fi
	echo -e 'cn = "'${ip}'"
organization = "'${lalala}'"
expiration_days = 365
signing_key
encryption_key
tls_www_server' > server.tmpl
	[[ $? != 0 ]] && echo -e "${Error} 寫入SSL證書籤名模板失敗(server.tmpl) !" && over
	certtool --generate-privkey --outfile server-key.pem
	[[ $? != 0 ]] && echo -e "${Error} 生成SSL證書密匙檔案失敗(server-key.pem) !" && over
	certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
	[[ $? != 0 ]] && echo -e "${Error} 生成SSL證書檔案失敗(server-cert.pem) !" && over
	
	mkdir /etc/ocserv/ssl
	mv ca-cert.pem /etc/ocserv/ssl/ca-cert.pem
	mv ca-key.pem /etc/ocserv/ssl/ca-key.pem
	mv server-cert.pem /etc/ocserv/ssl/server-cert.pem
	mv server-key.pem /etc/ocserv/ssl/server-key.pem
	cd .. && rm -rf /tmp/ssl/
}
Installation_dependency(){
	[[ ! -e "/dev/net/tun" ]] && echo -e "${Error} 你的VPS沒有開啟TUN，請聯繫IDC或透過VPS控制面板打開TUN/TAP開關 !" && exit 1
	if [[ ${release} = "centos" ]]; then
		echo -e "${Error} 本腳本不支援 CentOS 系統 !" && exit 1
	elif [[ ${release} = "debian" ]]; then
		mv /etc/apt/sources.list /etc/apt/sources.list.bak
		wget --no-check-certificate -O "/etc/apt/sources.list" "https://raw.githubusercontent.com/david082321/doubi/master/sources/us.sources.list"
		apt-get update
		apt-get install vim net-tools pkg-config build-essential libgnutls28-dev libwrap0-dev liblz4-dev libseccomp-dev libreadline-dev libnl-nf-3-dev libev-dev gnutls-bin -y
		rm -rf /etc/apt/sources.list
		mv /etc/apt/sources.list.bak /etc/apt/sources.list
		apt-get update
	else
		apt-get update
		apt-get install vim net-tools pkg-config build-essential libgnutls28-dev libwrap0-dev liblz4-dev libseccomp-dev libreadline-dev libnl-nf-3-dev libev-dev gnutls-bin -y
	fi
}
Install_ocserv(){
	[[ -e ${file} ]] && echo -e "${Error} ocserv 已安裝，請檢查 !" && exit 1
	echo -e "${Info} 開始安裝/設定 依賴..."
	Installation_dependency
	echo -e "${Info} 開始下載/安裝 設定檔案..."
	Download_ocserv
	echo -e "${Info} 開始下載/安裝 服務腳本(init)..."
	Service_ocserv
	echo -e "${Info} 開始自簽SSL證書..."
	Generate_SSL
	echo -e "${Info} 開始設定帳號設定..."
	Read_config
	Set_Config
	echo -e "${Info} 開始設定 iptables防火牆..."
	Set_iptables
	echo -e "${Info} 開始添加 iptables防火牆規則..."
	Add_iptables
	echo -e "${Info} 開始儲存 iptables防火牆規則..."
	Save_iptables
	echo -e "${Info} 所有步驟 安裝完畢，開始啟動..."
	Start_ocserv
}
Start_ocserv(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} ocserv 正在執行，請檢查 !" && exit 1
	/etc/init.d/ocserv start
	sleep 2s
	check_pid
	[[ ! -z ${PID} ]] && View_Config
}
Stop_ocserv(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} ocserv 沒有執行，請檢查 !" && exit 1
	/etc/init.d/ocserv stop
}
Restart_ocserv(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/ocserv stop
	/etc/init.d/ocserv start
	sleep 2s
	check_pid
	[[ ! -z ${PID} ]] && View_Config
}
Set_ocserv(){
	[[ ! -e ${conf} ]] && echo -e "${Error} ocserv 設定檔案不存在 !" && exit 1
	tcp_port=$(cat ${conf}|grep "tcp-port ="|awk -F ' = ' '{print $NF}')
	udp_port=$(cat ${conf}|grep "udp-port ="|awk -F ' = ' '{print $NF}')
	vim ${conf}
	set_tcp_port=$(cat ${conf}|grep "tcp-port ="|awk -F ' = ' '{print $NF}')
	set_udp_port=$(cat ${conf}|grep "udp-port ="|awk -F ' = ' '{print $NF}')
	Del_iptables
	Add_iptables
	Save_iptables
	echo "是否重啟 ocserv ? (Y/n)"
	stty erase '^H' && read -p "(預設: Y):" yn
	[[ -z ${yn} ]] && yn="y"
	if [[ ${yn} == [Yy] ]]; then
		Restart_ocserv
	fi
}
Set_username(){
	echo "請輸入 要添加的VPN帳號 使用者名稱"
	stty erase '^H' && read -p "(預設: admin):" username
	[[ -z "${username}" ]] && username="admin"
	echo && echo -e "	使用者名稱 : ${Red_font_prefix}${username}${Font_color_suffix}" && echo
}
Set_passwd(){
	echo "請輸入 要添加的VPN帳號 密碼"
	stty erase '^H' && read -p "(預設: doub.io):" userpass
	[[ -z "${userpass}" ]] && userpass="doub.io"
	echo && echo -e "	密碼 : ${Red_font_prefix}${userpass}${Font_color_suffix}" && echo
}
Set_tcp_port(){
	while true
	do
	echo -e "請輸入VPN服務端的TCP埠"
	stty erase '^H' && read -p "(預設: 443):" set_tcp_port
	[[ -z "$set_tcp_port" ]] && set_tcp_port="443"
	expr ${set_tcp_port} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${set_tcp_port} -ge 1 ]] && [[ ${set_tcp_port} -le 65535 ]]; then
			echo && echo -e "	TCP埠 : ${Red_font_prefix}${set_tcp_port}${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} 請輸入正確的數位！"
		fi
	else
		echo -e "${Error} 請輸入正確的數位！"
	fi
	done
}
Set_udp_port(){
	while true
	do
	echo -e "請輸入VPN服務端的UDP埠"
	stty erase '^H' && read -p "(預設: ${set_tcp_port}):" set_udp_port
	[[ -z "$set_udp_port" ]] && set_udp_port="${set_tcp_port}"
	expr ${set_udp_port} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${set_udp_port} -ge 1 ]] && [[ ${set_udp_port} -le 65535 ]]; then
			echo && echo -e "	TCP埠 : ${Red_font_prefix}${set_udp_port}${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} 請輸入正確的數位！"
		fi
	else
		echo -e "${Error} 請輸入正確的數位！"
	fi
	done
}
Set_Config(){
	Set_username
	Set_passwd
	echo -e "${userpass}\n${userpass}"|ocpasswd -c ${passwd_file} ${username}
	Set_tcp_port
	Set_udp_port
	sed -i 's/tcp-port = '"$(echo ${tcp_port})"'/tcp-port = '"$(echo ${set_tcp_port})"'/g' ${conf}
	sed -i 's/udp-port = '"$(echo ${udp_port})"'/udp-port = '"$(echo ${set_udp_port})"'/g' ${conf}
}
Read_config(){
	[[ ! -e ${conf} ]] && echo -e "${Error} ocserv 設定檔案不存在 !" && exit 1
	conf_text=$(cat ${conf}|grep -v '#')
	tcp_port=$(echo -e "${conf_text}"|grep "tcp-port ="|awk -F ' = ' '{print $NF}')
	udp_port=$(echo -e "${conf_text}"|grep "udp-port ="|awk -F ' = ' '{print $NF}')
	max_same_clients=$(echo -e "${conf_text}"|grep "max-same-clients ="|awk -F ' = ' '{print $NF}')
	max_clients=$(echo -e "${conf_text}"|grep "max-clients ="|awk -F ' = ' '{print $NF}')
}
List_User(){
	[[ ! -e ${passwd_file} ]] && echo -e "${Error} ocserv 帳號設定檔案不存在 !" && exit 1
	User_text=$(cat ${passwd_file})
	if [[ ! -z ${User_text} ]]; then
		User_num=$(echo -e "${User_text}"|wc -l)
		user_list_all=""
		for((integer = 1; integer <= ${User_num}; integer++))
		do
			user_name=$(echo -e "${User_text}" | awk -F ':*:' '{print $1}' | sed -n "${integer}p")
			user_status=$(echo -e "${User_text}" | awk -F ':*:' '{print $NF}' | sed -n "${integer}p"|cut -c 1)
			if [[ ${user_status} == '!' ]]; then
				user_status="禁用"
			else
				user_status="啟用"
			fi
			user_list_all=${user_list_all}"使用者名稱: "${user_name}" 帳號狀態: "${user_status}"\n"
		done
		echo && echo -e "使用者總數 ${Green_font_prefix}"${User_num}"${Font_color_suffix}"
		echo -e ${user_list_all}
	fi
}
Add_User(){
	Set_username
	Set_passwd
	user_status=$(cat "${passwd_file}"|grep "${username}"':*:')
	[[ ! -z ${user_status} ]] && echo -e "${Error} 使用者名稱已存在 ![ ${username} ]" && exit 1
	echo -e "${userpass}\n${userpass}"|ocpasswd -c ${passwd_file} ${username}
	user_status=$(cat "${passwd_file}"|grep "${username}"':*:')
	if [[ ! -z ${user_status} ]]; then
		echo -e "${Info} 帳號添加成功 ![ ${username} ]"
	else
		echo -e "${Error} 帳號添加失敗 ![ ${username} ]" && exit 1
	fi
}
Del_User(){
	List_User
	[[ ${User_num} == 1 ]] && echo -e "${Error} 目前僅剩一個帳號設定，無法刪除 !" && exit 1
	echo -e "請輸入要刪除的VPN帳號的使用者名稱"
	stty erase '^H' && read -p "(預設取消):" Del_username
	[[ -z "${Del_username}" ]] && echo "已取消..." && exit 1
	user_status=$(cat "${passwd_file}"|grep "${Del_username}"':*:')
	[[ -z ${user_status} ]] && echo -e "${Error} 使用者名稱不存在 ! [${Del_username}]" && exit 1
	ocpasswd -c ${passwd_file} -d ${Del_username}
	user_status=$(cat "${passwd_file}"|grep "${Del_username}"':*:')
	if [[ -z ${user_status} ]]; then
		echo -e "${Info} 刪除成功 ! [${Del_username}]"
	else
		echo -e "${Error} 刪除失敗 ! [${Del_username}]" && exit 1
	fi
}
Modify_User_disabled(){
	List_User
	echo -e "請輸入要啟用/禁用的VPN帳號的使用者名稱"
	stty erase '^H' && read -p "(預設取消):" Modify_username
	[[ -z "${Modify_username}" ]] && echo "已取消..." && exit 1
	user_status=$(cat "${passwd_file}"|grep "${Modify_username}"':*:')
	[[ -z ${user_status} ]] && echo -e "${Error} 使用者名稱不存在 ! [${Modify_username}]" && exit 1
	user_status=$(cat "${passwd_file}" | grep "${Modify_username}"':*:' | awk -F ':*:' '{print $NF}' |cut -c 1)
	if [[ ${user_status} == '!' ]]; then
			ocpasswd -c ${passwd_file} -u ${Modify_username}
			user_status=$(cat "${passwd_file}" | grep "${Modify_username}"':*:' | awk -F ':*:' '{print $NF}' |cut -c 1)
			if [[ ${user_status} != '!' ]]; then
				echo -e "${Info} 啟用成功 ! [${Modify_username}]"
			else
				echo -e "${Error} 啟用失敗 ! [${Modify_username}]" && exit 1
			fi
		else
			ocpasswd -c ${passwd_file} -l ${Modify_username}
			user_status=$(cat "${passwd_file}" | grep "${Modify_username}"':*:' | awk -F ':*:' '{print $NF}' |cut -c 1)
			if [[ ${user_status} == '!' ]]; then
				echo -e "${Info} 禁用成功 ! [${Modify_username}]"
			else
				echo -e "${Error} 禁用失敗 ! [${Modify_username}]" && exit 1
			fi
		fi
}
Set_Pass(){
	check_installed_status
	echo && echo -e " 你要做什麼？
	
 ${Green_font_prefix} 0.${Font_color_suffix} 列出 帳號設定
————————
 ${Green_font_prefix} 1.${Font_color_suffix} 添加 帳號設定
 ${Green_font_prefix} 2.${Font_color_suffix} 刪除 帳號設定
————————
 ${Green_font_prefix} 3.${Font_color_suffix} 啟用/禁用 帳號設定
 
 注意：添加/修改/刪除 帳號設定後，VPN服務端會即時讀取，無需重啟服務端 !" && echo
	stty erase '^H' && read -p "(預設: 取消):" set_num
	[[ -z "${set_num}" ]] && echo "已取消..." && exit 1
	if [[ ${set_num} == "0" ]]; then
		List_User
	elif [[ ${set_num} == "1" ]]; then
		Add_User
	elif [[ ${set_num} == "2" ]]; then
		Del_User
	elif [[ ${set_num} == "3" ]]; then
		Modify_User_disabled
	else
		echo -e "${Error} 請輸入正確的數位[1-3]" && exit 1
	fi
}
View_Config(){
	Get_ip
	Read_config
	clear && echo "===================================================" && echo
	echo -e " AnyConnect 設定訊息：" && echo
	echo -e " I  P\t\t  : ${Green_font_prefix}${ip}${Font_color_suffix}"
	echo -e " TCP埠\t  : ${Green_font_prefix}${tcp_port}${Font_color_suffix}"
	echo -e " UDP埠\t  : ${Green_font_prefix}${udp_port}${Font_color_suffix}"
	echo -e " 單使用者設備數限制 : ${Green_font_prefix}${max_same_clients}${Font_color_suffix}"
	echo -e " 總使用者設備數限制 : ${Green_font_prefix}${max_clients}${Font_color_suffix}"
	echo -e "\n 使用者端連結請填寫 : ${Green_font_prefix}${ip}:${tcp_port}${Font_color_suffix}"
	echo && echo "==================================================="
}
View_Log(){
	[[ ! -e ${log_file} ]] && echo -e "${Error} ocserv 日誌檔案不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 終止查看日誌" && echo
	tail -f ${log_file}
}
Uninstall_ocserv(){
	check_installed_status "un"
	echo "確定要移除 ocserv ? (y/N)"
	echo
	stty erase '^H' && read -p "(預設: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID} && rm -f ${PID_FILE}
		Read_config
		Del_iptables
		Save_iptables
		update-rc.d -f ocserv remove
		rm -rf /etc/init.d/ocserv
		rm -rf "${conf_file}"
		rm -rf "${log_file}"
		cd '/usr/local/bin' && rm -f occtl
		rm -f ocpasswd
		cd '/usr/local/bin' && rm -f ocserv-fw
		cd '/usr/local/sbin' && rm -f ocserv
		cd '/usr/local/share/man/man8' && rm -f ocserv.8
		rm -f ocpasswd.8
		rm -f occtl.8
		echo && echo "ocserv 移除完成 !" && echo
	else
		echo && echo "移除已取消..." && echo
	fi
}
over(){
	update-rc.d -f ocserv remove
	rm -rf /etc/init.d/ocserv
	rm -rf "${conf_file}"
	rm -rf "${log_file}"
	cd '/usr/local/bin' && rm -f occtl
	rm -f ocpasswd
	cd '/usr/local/bin' && rm -f ocserv-fw
	cd '/usr/local/sbin' && rm -f ocserv
	cd '/usr/local/share/man/man8' && rm -f ocserv.8
	rm -f ocpasswd.8
	rm -f occtl.8
	echo && echo "安裝過程錯誤，ocserv 移除完成 !" && echo
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${set_tcp_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${set_udp_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${tcp_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${udp_port} -j ACCEPT
}
Save_iptables(){
	iptables-save > /etc/iptables.up.rules
}
Set_iptables(){
	echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
	sysctl -p
	ifconfig_status=$(ifconfig)
	if [[ -z ${ifconfig_status} ]]; then
		echo -e "${Error} ifconfig 未安裝 !"
		stty erase '^H' && read -p "請手動輸入你的網卡名(一般為 eth0，OpenVZ 虛擬化則為 venet0):" Network_card
		[[ -z "${Network_card}" ]] && echo "取消..." && exit 1
	else
		Network_card=$(ifconfig|grep "eth0")
		if [[ ! -z ${Network_card} ]]; then
			Network_card="eth0"
		else
			Network_card=$(ifconfig|grep "venet0")
			if [[ ! -z ${Network_card} ]]; then
				Network_card="venet0"
			else
				ifconfig
				stty erase '^H' && read -p "檢測到本伺服器的網卡非 eth0 和 venet0 請根據上面輸出的網卡訊息手動輸入你的網卡名:" Network_card
				[[ -z "${Network_card}" ]] && echo "取消..." && exit 1
			fi
		fi
	fi
	iptables -t nat -A POSTROUTING -o ${Network_card} -j MASQUERADE
	
	iptables-save > /etc/iptables.up.rules
	echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
	chmod +x /etc/network/if-pre-up.d/iptables
}
Update_Shell(){
	echo -e "目前版本為 [ ${sh_ver} ]，開始檢測最新版本..."
	sh_new_ver=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/david082321/doubi/master/ocserv.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 檢測最新版本失敗 !" && exit 1
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "發現新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
		stty erase '^H' && read -p "(預設: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			wget -N --no-check-certificate https://raw.githubusercontent.com/david082321/doubi/master/ocserv.sh && chmod +x ocserv.sh
			echo -e "腳本已更新為最新版本[ ${sh_new_ver} ] !"
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo -e "目前已是最新版本[ ${sh_new_ver} ] !"
	fi
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && echo -e "${Error} 本腳本不支援目前系統 ${release} !" && exit 1
echo && echo -e " ocserv 一鍵安裝管理腳本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/vpnzy-7 --
  
 ${Green_font_prefix}0.${Font_color_suffix} 升級腳本
————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安裝 ocserv
 ${Green_font_prefix}2.${Font_color_suffix} 移除 ocserv
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 啟動 ocserv
 ${Green_font_prefix}4.${Font_color_suffix} 停止 ocserv
 ${Green_font_prefix}5.${Font_color_suffix} 重啟 ocserv
————————————
 ${Green_font_prefix}6.${Font_color_suffix} 設定 帳號設定
 ${Green_font_prefix}7.${Font_color_suffix} 查看 設定訊息
 ${Green_font_prefix}8.${Font_color_suffix} 修改 設定檔案
 ${Green_font_prefix}9.${Font_color_suffix} 查看 日誌訊息
————————————" && echo
if [[ -e ${file} ]]; then
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
stty erase '^H' && read -p " 請輸入數字 [0-9]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_ocserv
	;;
	2)
	Uninstall_ocserv
	;;
	3)
	Start_ocserv
	;;
	4)
	Stop_ocserv
	;;
	5)
	Restart_ocserv
	;;
	6)
	Set_Pass
	;;
	7)
	View_Config
	;;
	8)
	Set_ocserv
	;;
	9)
	View_Log
	;;
	*)
	echo "請輸入正確數字 [0-9]"
	;;
esac
