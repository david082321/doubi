#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Brook
#	Version: 1.0.1
#	Author: Toyo
#	Blog: https://doub.io/wlzy-jc37/
#=================================================

sh_ver="1.0.1"
file="/usr/local/brook-pf"
brook_file="/usr/local/brook-pf/brook"
brook_conf="/usr/local/brook-pf/brook.conf"
brook_ver="/usr/local/brook-pf/ver.txt"
brook_log="/usr/local/brook-pf/brook.log"

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
	[[ ! -e ${brook_file} ]] && echo -e "${Error} Brook 沒有安裝，請檢查 !" && exit 1
}
check_pid(){
	PID=`ps -ef| grep "brook relays"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
check_new_ver(){
	if [[ "${Download_type}" == "1" ]]; then
		brook_new_ver=$(wget -qO- "https://softs.loan/?dir=%E7%A7%91%E5%AD%A6%E4%B8%8A%E7%BD%91/PC/Brook/Linux"|grep 'data-name="Brook-x64-v'|head -n 1|awk -F 'Linux/Brook-x64-' '{print $2}'|sed 's/\">//')
		if [[ -z ${brook_new_ver} ]]; then
			echo -e "${Error} Brook 最新版本獲取失敗，請手動獲取最新版本號[ https://github.com/txthinking/brook/releases ]"
			stty erase '^H' && read -p "請輸入版本號 [ 格式是日期 , 如 v20170330 ] :" brook_new_ver
			[[ -z "${brook_new_ver}" ]] && echo "取消..." && exit 1
		else
			echo -e "${Info} 檢測到 Brook 最新版本為 [ ${brook_new_ver} ]"
		fi
	else
		brook_new_ver=$(wget -qO- "https://github.com/txthinking/brook/tags"| grep "/txthinking/brook/releases/tag/"| head -n 1| awk -F "/tag/" '{print $2}'| sed 's/\">//')
		if [[ -z ${brook_new_ver} ]]; then
			echo -e "${Error} Brook 最新版本獲取失敗，請手動獲取最新版本號[ https://github.com/txthinking/brook/releases ]"
			stty erase '^H' && read -p "請輸入版本號 [ 格式是日期 , 如 v20170330 ] :" brook_new_ver
			[[ -z "${brook_new_ver}" ]] && echo "取消..." && exit 1
		else
			echo -e "${Info} 檢測到 Brook 最新版本為 [ ${brook_new_ver} ]"
		fi
	fi
}
check_ver_comparison(){
	brook_now_ver=$(${brook_file} -v|awk '{print $3}')
	[[ -z ${brook_now_ver} ]] && echo -e "${Error} Brook 目前版本獲取失敗 !" && exit 1
	brook_now_ver="v${brook_now_ver}"
	if [[ "${brook_now_ver}" != "${brook_new_ver}" ]]; then
		echo -e "${Info} 發現 Brook 已有新版本 [ ${brook_new_ver} ]"
		stty erase '^H' && read -p "是否更新 ? [Y/n] :" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			rm -rf ${brook_file}
			Download_brook
			Start_brook
		fi
	else
		echo -e "${Info} 目前 Brook 已是最新版本 [ ${brook_new_ver} ]" && exit 1
	fi
}
Download_brook(){
	cd ${file}
	if [[ "${Download_type}" == "1" ]]; then
		if [[ ${bit} == "x86_64" ]]; then
			wget --no-check-certificate -N "https://softs.loan/%E7%A7%91%E5%AD%A6%E4%B8%8A%E7%BD%91/PC/Brook/Linux/Brook-x64-${brook_new_ver}"
			mv "Brook-x64-${brook_new_ver}" brook
		else
			wget --no-check-certificate -N "https://softs.loan/%E7%A7%91%E5%AD%A6%E4%B8%8A%E7%BD%91/PC/Brook/Linux/Brook-x32-${brook_new_ver}"
			mv "Brook-x32-${brook_new_ver}" brook
		fi
	else
		if [[ ${bit} == "x86_64" ]]; then
			wget --no-check-certificate -N "https://github.com/txthinking/brook/releases/download/${brook_new_ver}/brook"
		else
			wget --no-check-certificate -N "https://github.com/txthinking/brook/releases/download/${brook_new_ver}/brook_linux_386"
			mv brook_linux_386 brook
		fi
	fi
	[[ ! -e "brook" ]] && echo -e "${Error} Brook 下載失敗 !" && exit 1
	chmod +x brook
}
Service_brook(){
	if [[ "${Download_type}" == "1" ]]; then
		if [[ ${release} = "centos" ]]; then
			if ! wget --no-check-certificate "https://softs.loan/Bash/other/brook-pf_centos" -O /etc/init.d/brook-pf; then
				echo -e "${Error} Brook服務 管理腳本下載失敗 !" && exit 1
			fi
			chmod +x /etc/init.d/brook-pf
			chkconfig --add brook-pf
			chkconfig brook-pf on
		else
			if ! wget --no-check-certificate "https://softs.loan/Bash/other/brook-pf_debian" -O /etc/init.d/brook-pf; then
				echo -e "${Error} Brook服務 管理腳本下載失敗 !" && exit 1
			fi
			chmod +x /etc/init.d/brook-pf
			update-rc.d -f brook-pf defaults
		fi
	else
		if [[ ${release} = "centos" ]]; then
			if ! wget --no-check-certificate https://raw.githubusercontent.com/david082321/doubi/master/other/brook-pf_centos -O /etc/init.d/brook-pf; then
				echo -e "${Error} Brook服務 管理腳本下載失敗 !" && exit 1
			fi
			chmod +x /etc/init.d/brook-pf
			chkconfig --add brook-pf
			chkconfig brook-pf on
		else
			if ! wget --no-check-certificate https://raw.githubusercontent.com/david082321/doubi/master/other/brook-pf_debian -O /etc/init.d/brook-pf; then
				echo -e "${Error} Brook服務 管理腳本下載失敗 !" && exit 1
			fi
			chmod +x /etc/init.d/brook-pf
			update-rc.d -f brook-pf defaults
		fi
	fi
	echo -e "${Info} Brook服務 管理腳本下載完成 !"
}
Installation_dependency(){
	cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	mkdir ${file}
}
Read_config(){
	[[ ! -e ${brook_conf} ]] && echo -e "${Error} Brook 設定檔案不存在 !" && exit 1
	user_all=$(cat ${brook_conf})
	user_all_num=$(echo "${user_all}"|wc -l)
	[[ -z ${user_all} ]] && echo -e "${Error} Brook 設定檔案中使用者設定為空 !" && exit 1
}
Set_pf_Enabled(){
	echo -e "立即啟用該埠轉發，還是禁用？ [Y/n]"
	stty erase '^H' && read -p "(預設: Y 啟用):" pf_Enabled_un
	[[ -z ${pf_Enabled_un} ]] && pf_Enabled_un="y"
	if [[ ${pf_Enabled_un} == [Yy] ]]; then
		bk_Enabled="1"
	else
		bk_Enabled="0"
	fi
}
Set_port_Modify(){
	while true
		do
		echo -e "請選擇並輸入要修改的 Brook 埠轉發本機監聽埠 [1-65535]"
		stty erase '^H' && read -p "(預設取消):" bk_port_Modify
		[[ -z "${bk_port_Modify}" ]] && echo "取消..." && exit 1
		expr ${bk_port_Modify} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${bk_port_Modify} -ge 1 ]] && [[ ${bk_port_Modify} -le 65535 ]]; then
				check_port "${bk_port_Modify}"
				if [[ $? == 0 ]]; then
					break
				else
					echo -e "${Error} 該本機監聽埠不存在 [${bk_port_Modify}] !"
				fi
			else
				echo "輸入錯誤, 請輸入正確的埠。"
			fi
		else
			echo "輸入錯誤, 請輸入正確的埠。"
		fi
	done
}
Set_port(){
	while true
		do
		echo -e "請輸入 Brook 本機監聽埠 [1-65535]（埠不能重複，避免衝突）"
		stty erase '^H' && read -p "(預設取消):" bk_port
		[[ -z "${bk_port}" ]] && echo "已取消..." && exit 1
		expr ${bk_port} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${bk_port} -ge 1 ]] && [[ ${bk_port} -le 65535 ]]; then
				echo && echo "========================"
				echo -e "	本機監聽埠 : ${Red_background_prefix} ${bk_port} ${Font_color_suffix}"
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
Set_IP_pf(){
	echo "請輸入被轉發的 IP :"
	stty erase '^H' && read -p "(預設取消):" bk_ip_pf
	[[ -z "${bk_ip_pf}" ]] && echo "已取消..." && exit 1
	echo && echo "========================"
	echo -e "	被轉發IP : ${Red_background_prefix} ${bk_ip_pf} ${Font_color_suffix}"
	echo "========================" && echo
}
Set_port_pf(){
	while true
		do
		echo -e "請輸入 Brook 被轉發的埠 [1-65535]"
		stty erase '^H' && read -p "(預設取消):" bk_port_pf
		[[ -z "${bk_port_pf}" ]] && echo "已取消..." && exit 1
		expr ${bk_port_pf} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${bk_port_pf} -ge 1 ]] && [[ ${bk_port_pf} -le 65535 ]]; then
				echo && echo "========================"
				echo -e "	被轉發埠 : ${Red_background_prefix} ${bk_port_pf} ${Font_color_suffix}"
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
Set_brook(){
	check_installed_status
	echo && echo -e "你要做什麼？
 ${Green_font_prefix}1.${Font_color_suffix}  添加 埠轉發
 ${Green_font_prefix}2.${Font_color_suffix}  刪除 埠轉發
 ${Green_font_prefix}3.${Font_color_suffix}  修改 埠轉發
 ${Green_font_prefix}4.${Font_color_suffix}  啟用/禁用 埠轉發
 
 ${Tip} 本機監聽埠不能重複，被轉發的IP或埠可重複!" && echo
	stty erase '^H' && read -p "(預設: 取消):" bk_modify
	[[ -z "${bk_modify}" ]] && echo "已取消..." && exit 1
	if [[ ${bk_modify} == "1" ]]; then
		Add_pf
	elif [[ ${bk_modify} == "2" ]]; then
		Del_pf
	elif [[ ${bk_modify} == "3" ]]; then
		Modify_pf
	elif [[ ${bk_modify} == "4" ]]; then
		Modify_Enabled_pf
	else
		echo -e "${Error} 請輸入正確的數位(1-4)" && exit 1
	fi
}
check_port(){
	check_port_1=$1
	user_all=$(cat ${brook_conf}|sed '1d;/^\s*$/d')
	#[[ -z "${user_all}" ]] && echo -e "${Error} Brook 設定檔案中使用者設定為空 !" && exit 1
	check_port_statu=$(echo "${user_all}"|awk '{print $1}'|grep -w "${check_port_1}")
	if [[ ! -z "${check_port_statu}" ]]; then
		return 0
	else
		return 1
	fi
}
list_port(){
	port_Type=$1
	user_all=$(cat ${brook_conf}|sed '/^\s*$/d')
	if [[ -z "${user_all}" ]]; then
		if [[ "${port_Type}" == "ADD" ]]; then
			echo -e "${Info} 目前 Brook 設定檔案中使用者設定為空。"
		else
			echo -e "${Info} 目前 Brook 設定檔案中使用者設定為空。" && exit 1
		fi
	else
		user_num=$(echo -e "${user_all}"|wc -l)
		for((integer = 1; integer <= ${user_num}; integer++))
		do
			user_port=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $1}')
			user_ip_pf=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $2}')
			user_port_pf=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $3}')
			user_Enabled_pf=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $4}')
			if [[ ${user_Enabled_pf} == "0" ]]; then
				user_Enabled_pf_1="${Red_font_prefix}禁用${Font_color_suffix}"
			else
				user_Enabled_pf_1="${Green_font_prefix}啟用${Font_color_suffix}"
			fi
			user_list_all=${user_list_all}"本機監聽埠: ${Green_font_prefix}"${user_port}"${Font_color_suffix}\t 被轉發IP: ${Green_font_prefix}"${user_ip_pf}"${Font_color_suffix}\t 被轉發埠: ${Green_font_prefix}"${user_port_pf}"${Font_color_suffix}\t 狀態: ${user_Enabled_pf_1}\n"
			user_IP=""
		done
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
		echo -e "目前埠轉發總數: ${Green_background_prefix} "${user_num}" ${Font_color_suffix} 目前伺服器IP: ${Green_background_prefix} "${ip}" ${Font_color_suffix}"
		echo -e "${user_list_all}"
		echo -e "========================\n"
	fi
}
Add_pf(){
	while true
	do
		list_port "ADD"
		Set_port
		check_port "${bk_port}"
		[[ $? == 0 ]] && echo -e "${Error} 該本機監聽埠已使用 [${bk_port}] !" && exit 1
		Set_IP_pf
		Set_port_pf
		Set_pf_Enabled
		echo "${bk_port} ${bk_ip_pf} ${bk_port_pf} ${bk_Enabled}" >> ${brook_conf}
		Add_success=$(cat ${brook_conf}| grep ${bk_port})
		if [[ -z "${Add_success}" ]]; then
			echo -e "${Error} 埠轉發 添加失敗 ${Green_font_prefix}[埠: ${bk_port} 被轉發IP和埠: ${bk_ip_pf}:${bk_port_pf}]${Font_color_suffix} "
			break
		else
			Add_iptables
			Save_iptables
			echo -e "${Info} 埠轉發 添加成功 ${Green_font_prefix}[埠: ${bk_port} 被轉發IP和埠: ${bk_ip_pf}:${bk_port_pf}]${Font_color_suffix}\n"
			stty erase '^H' && read -p "是否繼續 添加埠轉發設定？[Y/n]:" addyn
			[[ -z ${addyn} ]] && addyn="y"
			if [[ ${addyn} == [Nn] ]]; then
				Restart_brook
				break
			else
				echo -e "${Info} 繼續 添加埠轉發設定..."
				user_list_all=""
			fi
		fi
	done
}
Del_pf(){
	while true
	do
		list_port
		Set_port
		check_port "${bk_port}"
		[[ $? == 1 ]] && echo -e "${Error} 該本機監聽埠不存在 [${bk_port}] !" && exit 1
		sed -i "/^${bk_port} /d" ${brook_conf}
		Del_success=$(cat ${brook_conf}| grep ${bk_port})
		if [[ ! -z "${Del_success}" ]]; then
			echo -e "${Error} 埠轉發 刪除失敗 ${Green_font_prefix}[埠: ${bk_port}]${Font_color_suffix} "
			break
		else
			port=${bk_port}
			Del_iptables
			Save_iptables
			echo -e "${Info} 埠轉發 刪除成功 ${Green_font_prefix}[埠: ${bk_port}]${Font_color_suffix}\n"
			port_num=$(cat ${brook_conf}|sed '/^\s*$/d'|wc -l)
			if [[ ${port_num} == 0 ]]; then
				echo -e "${Error} 已無任何埠 !"
				check_pid
				if [[ ! -z ${PID} ]]; then
					Stop_brook
				fi
				break
			else
				stty erase '^H' && read -p "是否繼續 刪除埠轉發設定？[Y/n]:" delyn
				[[ -z ${delyn} ]] && delyn="y"
				if [[ ${delyn} == [Nn] ]]; then
					Restart_brook
					break
				else
					echo -e "${Info} 繼續 刪除埠轉發設定..."
					user_list_all=""
				fi
			fi
		fi
	done
}
Modify_pf(){
	list_port
	Set_port_Modify
	echo -e "\n${Info} 開始輸入新埠... \n"
	Set_port
	check_port "${bk_port}"
	[[ $? == 0 ]] && echo -e "${Error} 該埠已存在 [${bk_port}] !" && exit 1
	Set_IP_pf
	Set_port_pf
	sed -i "/^${bk_port_Modify} /d" ${brook_conf}
	Set_pf_Enabled
	echo "${bk_port} ${bk_ip_pf} ${bk_port_pf} ${bk_Enabled}" >> ${brook_conf}
	Modify_success=$(cat ${brook_conf}| grep "${bk_port} ${bk_ip_pf} ${bk_port_pf} ${bk_Enabled}")
	if [[ -z "${Modify_success}" ]]; then
		echo -e "${Error} 埠轉發 修改失敗 ${Green_font_prefix}[埠: ${bk_port} 被轉發IP和埠: ${bk_ip_pf}:${bk_port_pf}]${Font_color_suffix}"
		exit 1
	else
		port=${bk_port_Modify}
		Del_iptables
		Add_iptables
		Save_iptables
		Restart_brook
		echo -e "${Info} 埠轉發 修改成功 ${Green_font_prefix}[埠: ${bk_port} 被轉發IP和埠: ${bk_ip_pf}:${bk_port_pf}]${Font_color_suffix}\n"
	fi
}
Modify_Enabled_pf(){
	list_port
	Set_port_Modify
	user_pf_text=$(cat ${brook_conf}|sed '/^\s*$/d'|grep "${bk_port_Modify}")
	user_port_text=$(echo ${user_pf_text}|awk '{print $1}')
	user_ip_pf_text=$(echo ${user_pf_text}|awk '{print $2}')
	user_port_pf_text=$(echo ${user_pf_text}|awk '{print $3}')
	user_Enabled_pf_text=$(echo ${user_pf_text}|awk '{print $4}')
	if [[ ${user_Enabled_pf_text} == "0" ]]; then
		echo -e "該埠轉發已${Red_font_prefix}禁用${Font_color_suffix}，是否${Green_font_prefix}啟用${Font_color_suffix}？ [Y/n]"
		stty erase '^H' && read -p "(預設: Y 啟用):" user_Enabled_pf_text_un
		[[ -z ${user_Enabled_pf_text_un} ]] && user_Enabled_pf_text_un="y"
		if [[ ${user_Enabled_pf_text_un} == [Yy] ]]; then
			user_Enabled_pf_text_1="1"
			sed -i "/^${bk_port_Modify} /d" ${brook_conf}
			echo "${user_port_text} ${user_ip_pf_text} ${user_port_pf_text} ${user_Enabled_pf_text_1}" >> ${brook_conf}
			Modify_Enabled_success=$(cat ${brook_conf}| grep "${user_port_text} ${user_ip_pf_text} ${user_port_pf_text} ${user_Enabled_pf_text_1}")
			if [[ -z "${Modify_Enabled_success}" ]]; then
				echo -e "${Error} 埠轉發 啟用失敗 ${Green_font_prefix}[埠: ${user_port_text} 被轉發IP和埠: ${user_ip_pf_text}:${user_port_pf_text}]${Font_color_suffix}"
				exit 1
			else
				echo -e "${Info} 埠轉發 啟用成功 ${Green_font_prefix}[埠: ${user_port_text} 被轉發IP和埠: ${user_ip_pf_text}:${user_port_pf_text}]${Font_color_suffix}\n"
				Restart_brook
			fi
		else
			echo "已取消..." && exit 0
		fi
	else
		echo -e "該埠轉發已${Green_font_prefix}啟用${Font_color_suffix}，是否${Red_font_prefix}禁用${Font_color_suffix}？ [Y/n]"
		stty erase '^H' && read -p "(預設: Y 禁用):" user_Enabled_pf_text_un
		[[ -z ${user_Enabled_pf_text_un} ]] && user_Enabled_pf_text_un="y"
		if [[ ${user_Enabled_pf_text_un} == [Yy] ]]; then
			user_Enabled_pf_text_1="0"
			sed -i "/^${bk_port_Modify} /d" ${brook_conf}
			echo "${user_port_text} ${user_ip_pf_text} ${user_port_pf_text} ${user_Enabled_pf_text_1}" >> ${brook_conf}
			Modify_Enabled_success=$(cat ${brook_conf}| grep "${user_port_text} ${user_ip_pf_text} ${user_port_pf_text} ${user_Enabled_pf_text_1}")
			if [[ -z "${Modify_Enabled_success}" ]]; then
				echo -e "${Error} 埠轉發 禁用失敗 ${Green_font_prefix}[埠: ${user_port_text} 被轉發IP和埠: ${user_ip_pf_text}:${user_port_pf_text}]${Font_color_suffix}"
				exit 1
			else
				echo -e "${Info} 埠轉發 禁用成功 ${Green_font_prefix}[埠: ${user_port_text} 被轉發IP和埠: ${user_ip_pf_text}:${user_port_pf_text}]${Font_color_suffix}\n"
				Restart_brook
			fi
		else
			echo "已取消..." && exit 0
		fi
	fi
}
Install_brook(){
	[[ -e ${brook_file} ]] && echo -e "${Error} 檢測到 Brook 已安裝 !" && exit 1
	echo -e "${Info} 開始安裝/設定 依賴..."
	Installation_dependency
	
	echo && echo -e "請選擇你的伺服器是國內還是國外
 ${Green_font_prefix}1.${Font_color_suffix}  國內伺服器(逗比雲)
 ${Green_font_prefix}2.${Font_color_suffix}  國外伺服器(Github)
 
 ${Tip} 因為國內對 Github 限速，這會導致國內伺服器下載速度極慢，所以選擇 國內伺服器 選項就會從我的 逗比雲 下載!" && echo
	stty erase '^H' && read -p "(預設: 2 國外伺服器):" bk_Download
	[[ -z "${bk_Download}" ]] && bk_Download="2"
	if [[ ${bk_Download} == "1" ]]; then
		Download_type="1"
	else
		Download_type="2"
	fi
	echo -e "${Info} 開始檢測最新版本..."
	check_new_ver
	echo -e "${Info} 開始下載/安裝..."
	Download_brook
	
	echo -e "${Info} 開始下載/安裝 服務腳本(init)..."
	Service_brook
	echo -e "${Info} 開始寫入 設定檔案..."
	echo "" > ${brook_conf}
	echo -e "${Info} 開始設定 iptables防火牆..."
	Set_iptables
	echo -e "${Info} Brook 安裝完成！預設設定檔案為空，請選擇 [7.設定 Brook 埠轉發 - 1.添加 埠轉發] 來添加埠轉發。"
}
Start_brook(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} Brook 正在執行，請檢查 !" && exit 1
	/etc/init.d/brook-pf start
}
Stop_brook(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} Brook 沒有執行，請檢查 !" && exit 1
	/etc/init.d/brook-pf stop
}
Restart_brook(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/brook-pf stop
	/etc/init.d/brook-pf start
}
Update_brook(){
	check_installed_status
	echo && echo -e "請選擇你的伺服器是國內還是國外
 ${Green_font_prefix}1.${Font_color_suffix}  國內伺服器(逗比雲)
 ${Green_font_prefix}2.${Font_color_suffix}  國外伺服器(Github)
 
 ${Tip} 因為國內對 Github 限速，這會導致國內伺服器下載速度極慢，所以選擇 國內伺服器 選項就會從我的 逗比雲 下載!" && echo
	stty erase '^H' && read -p "(預設: 2 國外伺服器):" bk_Download
	[[ -z "${bk_Download}" ]] && bk_Download="2"
	if [[ ${bk_Download} == "1" ]]; then
		Download_type="1"
	else
		Download_type="2"
	fi
	check_new_ver
	check_ver_comparison
}
Uninstall_brook(){
	check_installed_status
	echo -e "確定要移除 Brook ? [y/N]\n"
	stty erase '^H' && read -p "(預設: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		if [[ -e ${brook_conf} ]]; then
			user_all=$(cat ${brook_conf}|sed '/^\s*$/d')
			user_all_num=$(echo "${user_all}"|wc -l)
			if [[ ! -z ${user_all} ]]; then
				for((integer = 1; integer <= ${user_all_num}; integer++))
				do
					port=$(echo "${user_all}"|sed -n "${integer}p"|awk '{print $1}')
					Del_iptables
				done
			fi
		fi
		rm -rf ${file}
		if [[ ${release} = "centos" ]]; then
			chkconfig --del brook-pf
		else
			update-rc.d -f brook-pf remove
		fi
		rm -rf /etc/init.d/brook-pf
		echo && echo "Brook 移除完成 !" && echo
	else
		echo && echo "移除已取消..." && echo
	fi
}
View_Log(){
	check_installed_status
	[[ ! -e ${brook_log} ]] && echo -e "${Error} Brook 日誌檔案不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 終止查看日誌(正常情況是沒有使用日誌記錄的)" && echo
	tail -f ${brook_log}
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${bk_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${bk_port} -j ACCEPT
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
	sh_new_ver=$(wget --no-check-certificate -qO- "https://softs.loan/Bash/brook-pf.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="softs"
	[[ -z ${sh_new_ver} ]] && sh_new_ver=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/david082321/doubi/master/brook-pf.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 檢測最新版本失敗 !" && exit 0
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "發現新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
		stty erase '^H' && read -p "(預設: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			if [[ $sh_new_type == "softs" ]]; then
				wget -N --no-check-certificate https://softs.loan/Bash/brook-pf.sh && chmod +x brook.sh
			else
				wget -N --no-check-certificate https://raw.githubusercontent.com/david082321/doubi/master/brook-pf.sh && chmod +x brook.sh
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
echo && echo -e "  Brook 埠轉發 一鍵管理腳本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  ---- Toyo | doub.io/wlzy-jc37 ----
  
 ${Green_font_prefix}0.${Font_color_suffix} 升級腳本
————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安裝 Brook
 ${Green_font_prefix}2.${Font_color_suffix} 升級 Brook
 ${Green_font_prefix}3.${Font_color_suffix} 移除 Brook
————————————
 ${Green_font_prefix}4.${Font_color_suffix} 啟動 Brook
 ${Green_font_prefix}5.${Font_color_suffix} 停止 Brook
 ${Green_font_prefix}6.${Font_color_suffix} 重啟 Brook
————————————
 ${Green_font_prefix}7.${Font_color_suffix} 設定 Brook 埠轉發
 ${Green_font_prefix}8.${Font_color_suffix} 查看 Brook 埠轉發
 ${Green_font_prefix}9.${Font_color_suffix} 查看 Brook 日誌
————————————" && echo
if [[ -e ${brook_file} ]]; then
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
	Install_brook
	;;
	2)
	Update_brook
	;;
	3)
	Uninstall_brook
	;;
	4)
	Start_brook
	;;
	5)
	Stop_brook
	;;
	6)
	Restart_brook
	;;
	7)
	Set_brook
	;;
	8)
	check_installed_status
	list_port
	;;
	9)
	View_Log
	;;
	*)
	echo "請輸入正確數字 [0-9]"
	;;
esac
