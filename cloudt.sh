#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Cloud Torrent
#	Version: 1.2.2
#	Author: Toyo
#	Blog: https://doub.io/wlzy-12/
#=================================================

file="/usr/local/cloudtorrent"
ct_file="/usr/local/cloudtorrent/cloud-torrent"
dl_file="/usr/local/cloudtorrent/downloads"
ct_config="/usr/local/cloudtorrent/cloud-torrent.json"
ct_conf="/usr/local/cloudtorrent/cloud-torrent.conf"
ct_log="/tmp/ct.log"
IncomingPort="50007"

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
	bit=$(uname -m)
}
check_installed_status(){
	[[ ! -e ${ct_file} ]] && echo -e "${Error} Cloud Torrent 沒有安裝，請檢查 !" && exit 1
}
check_pid(){
	PID=$(ps -ef | grep cloud-torrent | grep -v grep | awk '{print $2}')
}
check_new_ver(){
	ct_new_ver=$(wget --no-check-certificate -qO- https://github.com/jpillora/cloud-torrent/releases/latest | grep "<title>" | sed -r 's/.*Release (.+) · jpillora.*/\1/')
	if [[ -z ${ct_new_ver} ]]; then
		echo -e "${Error} Cloud Torrent 最新版本獲取失敗，請手動獲取最新版本號[ https://github.com/jpillora/cloud-torrent/releases ]"
		stty erase '^H' && read -p "請輸入版本號 [ 格式 x.x.xx , 如 0.8.21 ] :" ct_new_ver
		[[ -z "${ct_new_ver}" ]] && echo "取消..." && exit 1
	else
		echo -e "${Info} Cloud Torrent 目前最新版本為 ${ct_new_ver}"
	fi
}
check_ver_comparison(){
	ct_now_ver=$(${ct_file} --version)
	if [[ ${ct_now_ver} != ${ct_new_ver} ]]; then
		echo -e "${Info} 發現 Cloud Torrent 已有新版本 [ ${ct_new_ver} ]"
		stty erase '^H' && read -p "是否更新 ? [Y/n] :" yn
		[ -z "${yn}" ] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			rm -rf ${ct_file}
			Download_ct
			Start_ct
		fi
	else
		echo -e "${Info} 目前 Cloud Torrent 已是最新版本 [ ${ct_new_ver} ]" && exit 1
	fi
}
Download_ct(){
	cd ${file}
	if [[ ${bit} == "x86_64" ]]; then
		wget --no-check-certificate -O cloud-torrent.gz "https://github.com/jpillora/cloud-torrent/releases/download/${ct_new_ver}/cloud-torrent_linux_amd64.gz"
	else
		wget --no-check-certificate -O cloud-torrent.gz "https://github.com/jpillora/cloud-torrent/releases/download/${ct_new_ver}/cloud-torrent_linux_386.gz"
	fi
	[[ ! -e "cloud-torrent.gz" ]] && echo -e "${Error} Cloud Torrent 下載失敗 !" && exit 1
	gzip -d cloud-torrent.gz
	[[ ! -e ${ct_file} ]] && echo -e "${Error} Cloud Torrent 解壓失敗(可能是 壓縮包損壞 或者 沒有安裝 Gzip) !" && exit 1
	rm -rf cloud-torrent.gz
	chmod +x cloud-torrent
}
Service_ct(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/david082321/doubi/master/other/cloudt_centos" -O /etc/init.d/cloudt; then
			echo -e "${Error} Cloud Torrent服務 管理腳本下載失敗 !" && exit 1
		fi
		chmod +x /etc/init.d/cloudt
		chkconfig --add cloudt
		chkconfig cloudt on
	else
		if ! wget --no-check-certificate "https://raw.githubusercontent.com/david082321/doubi/master/other/cloudt_debian" -O /etc/init.d/cloudt; then
			echo -e "${Error} Cloud Torrent服務 管理腳本下載失敗 !" && exit 1
		fi
		chmod +x /etc/init.d/cloudt
		update-rc.d -f cloudt defaults
	fi
	echo -e "${Info} Cloud Torrent服務 管理腳本下載完成 !"
}
Installation_dependency(){
	gzip_ver=$(gzip -V)
	if [[ -z ${gzip_ver} ]]; then
		if [[ ${release} == "centos" ]]; then
			yum update
			yum install -y gzip
		else
			apt-get update
			apt-get install -y gzip
		fi
	fi
	mkdir ${file}
	mkdir ${dl_file}
}
Write_config(){
	cat > ${ct_conf}<<-EOF
host = ${ct_host}
port = ${ct_port}
user = ${ct_user}
passwd = ${ct_passwd}
EOF
}
Read_config(){
	[[ ! -e ${ct_conf} ]] && echo -e "${Error} Cloud Torrent 設定檔案不存在 !" && exit 1
	host=`cat ${ct_conf}|grep "host = "|awk -F "host = " '{print $NF}'`
	port=`cat ${ct_conf}|grep "port = "|awk -F "port = " '{print $NF}'`
	user=`cat ${ct_conf}|grep "user = "|awk -F "user = " '{print $NF}'`
	passwd=`cat ${ct_conf}|grep "passwd = "|awk -F "passwd = " '{print $NF}'`
}
Set_host(){
	echo -e "請輸入 Cloud Torrent 監聽域名或IP（當你要綁定域名前，記得先做好域名解析，目前只支援http://訪問，不要寫http://，只寫域名！）"
	stty erase '^H' && read -p "(預設: 0.0.0.0 監聽網卡所有IP):" ct_host
	[[ -z "${ct_host}" ]] && ct_host="0.0.0.0"
	echo && echo "========================"
	echo -e "	主機 : ${Red_background_prefix} ${ct_host} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_port(){
	while true
		do
		echo -e "請輸入 Cloud Torrent 監聽埠 [1-65535]（如果是綁定的域名，那麼建議80埠）"
		stty erase '^H' && read -p "(預設埠: 80):" ct_port
		[[ -z "${ct_port}" ]] && ct_port="80"
		expr ${ct_port} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${ct_port} -ge 1 ]] && [[ ${ct_port} -le 65535 ]]; then
				echo && echo "========================"
				echo -e "	埠 : ${Red_background_prefix} ${ct_port} ${Font_color_suffix}"
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
Set_user(){
	echo "請輸入 Cloud Torrent 使用者名稱"
	stty erase '^H' && read -p "(預設使用者名稱: user):" ct_user
	[[ -z "${ct_user}" ]] && ct_user="user"
	echo && echo "========================"
	echo -e "	使用者名稱 : ${Red_background_prefix} ${ct_user} ${Font_color_suffix}"
	echo "========================" && echo

	echo "請輸入 Cloud Torrent 使用者名稱的密碼"
	stty erase '^H' && read -p "(預設密碼: doub.io):" ct_passwd
	[[ -z "${ct_passwd}" ]] && ct_passwd="doub.io"
	echo && echo "========================"
	echo -e "	密碼 : ${Red_background_prefix} ${ct_passwd} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_conf(){
	Set_host
	Set_port
	stty erase '^H' && read -p "是否設定 使用者名稱和密碼 ? [y/N] :" yn
	[[ -z "${yn}" ]] && yn="n"
	if [[ ${yn} == [Yy] ]]; then
		Set_user
	else
		ct_user="" && ct_passwd=""
	fi
}
Set_ct(){
	check_installed_status
	check_sys
	check_pid
	Set_conf
	Read_config
	Del_iptables
	Write_config
	Add_iptables
	Save_iptables
	Restart_ct
}
Install_ct(){
	[[ -e ${ct_file} ]] && echo -e "${Error} 檢測到 Cloud Torrent 已安裝 !" && exit 1
	check_sys
	echo -e "${Info} 開始設定 使用者設定..."
	Set_conf
	echo -e "${Info} 開始安裝/設定 依賴..."
	Installation_dependency
	echo -e "${Info} 開始檢測最新版本..."
	check_new_ver
	echo -e "${Info} 開始下載/安裝..."
	Download_ct
	echo -e "${Info} 開始下載/安裝 服務腳本(init)..."
	Service_ct
	echo -e "${Info} 開始寫入 設定檔案..."
	Write_config
	echo -e "${Info} 開始設定 iptables防火牆..."
	Set_iptables
	echo -e "${Info} 開始添加 iptables防火牆規則..."
	Add_iptables
	echo -e "${Info} 開始儲存 iptables防火牆規則..."
	Save_iptables
	echo -e "${Info} 所有步驟 安裝完畢，開始啟動..."
	Start_ct
}
Start_ct(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} Cloud Torrent 正在執行，請檢查 !" && exit 1
	/etc/init.d/cloudt start
}
Stop_ct(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} Cloud Torrent 沒有執行，請檢查 !" && exit 1
	/etc/init.d/cloudt stop
}
Restart_ct(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/cloudt stop
	/etc/init.d/cloudt start
}
Log_ct(){
	[[ ! -e "${ct_log}" ]] && echo -e "${Error} Cloud Torrent 日誌檔案不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 終止查看日誌" && echo
	tail -f "${ct_log}"
}
Update_ct(){
	check_installed_status
	check_sys
	check_new_ver
	check_ver_comparison
	/etc/init.d/cloudt start
}
Uninstall_ct(){
	check_installed_status
	echo "確定要移除 Cloud Torrent ? (y/N)"
	echo
	stty erase '^H' && read -p "(預設: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config
		Del_iptables
		rm -rf ${file} && rm -rf /etc/init.d/cloudt
		if [[ ${release} = "centos" ]]; then
			chkconfig --del cloudt
		else
			update-rc.d -f cloudt remove
		fi
		echo && echo "Cloud torrent 移除完成 !" && echo
	else
		echo && echo "移除已取消..." && echo
	fi
}
View_ct(){
	check_installed_status
	Read_config
	if [[ "${host}" == "0.0.0.0" ]]; then
		host=$(wget -qO- -t1 -T2 ipinfo.io/ip)
		if [[ -z "${host}" ]]; then
			host=$(wget -qO- -t1 -T2 api.ip.sb/ip)
			if [[ -z "${host}" ]]; then
				host=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
				if [[ -z "${host}" ]]; then
					host="VPS_IP"
				fi
			fi
		fi
	fi
	if [[ "${port}" == "80" ]]; then
		port=""
	else
		port=":${port}"
	fi
	if [[ -z ${user} ]]; then
		clear && echo "————————————————" && echo
		echo -e " 你的 Cloud Torrent 訊息 :" && echo
		echo -e " 地址\t: ${Green_font_prefix}http://${host}${port}${Font_color_suffix}"
		echo && echo "————————————————"
	else
		clear && echo "————————————————" && echo
		echo -e " 你的 Cloud Torrent 訊息 :" && echo
		echo -e " 地址\t: ${Green_font_prefix}http://${host}${port}${Font_color_suffix}"
		echo -e " 使用者\t: ${Green_font_prefix}${user}${Font_color_suffix}"
		echo -e " 密碼\t: ${Green_font_prefix}${passwd}${Font_color_suffix}"
		echo && echo "————————————————"
	fi
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${ct_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${ct_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${IncomingPort} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${IncomingPort} -j ACCEPT
	iptables -I OUTPUT -m state --state NEW -m tcp -p tcp --dport ${IncomingPort} -j ACCEPT
	iptables -I OUTPUT -m state --state NEW -m udp -p udp --dport ${IncomingPort} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${IncomingPort} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${IncomingPort} -j ACCEPT
	iptables -D OUTPUT -m state --state NEW -m tcp -p tcp --dport ${IncomingPort} -j ACCEPT
	iptables -D OUTPUT -m state --state NEW -m udp -p udp --dport ${IncomingPort} -j ACCEPT
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
echo && echo -e "請輸入一個數字來選擇選項

 ${Green_font_prefix}1.${Font_color_suffix} 安裝 Cloud Torrent
 ${Green_font_prefix}2.${Font_color_suffix} 升級 Cloud Torrent
 ${Green_font_prefix}3.${Font_color_suffix} 移除 Cloud Torrent
————————————
 ${Green_font_prefix}4.${Font_color_suffix} 啟動 Cloud Torrent
 ${Green_font_prefix}5.${Font_color_suffix} 停止 Cloud Torrent
 ${Green_font_prefix}6.${Font_color_suffix} 重啟 Cloud Torrent
————————————
 ${Green_font_prefix}7.${Font_color_suffix} 設定 Cloud Torrent 帳號
 ${Green_font_prefix}8.${Font_color_suffix} 查看 Cloud Torrent 帳號
 ${Green_font_prefix}9.${Font_color_suffix} 查看 Cloud Torrent 日誌
————————————" && echo
if [[ -e ${ct_file} ]]; then
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
stty erase '^H' && read -p " 請輸入數字 [1-9]:" num
case "$num" in
	1)
	Install_ct
	;;
	2)
	Update_ct
	;;
	3)
	Uninstall_ct
	;;
	4)
	Start_ct
	;;
	5)
	Stop_ct
	;;
	6)
	Restart_ct
	;;
	7)
	Set_ct
	;;
	8)
	View_ct
	;;
	9)
	Log_ct
	;;
	*)
	echo "請輸入正確數字 [1-9]"
	;;
esac
