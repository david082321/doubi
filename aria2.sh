#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Aria2
#	Version: 1.1.8
#	Author: Toyo
#	Blog: https://doub.io/shell-jc4/
#=================================================
sh_ver="1.1.8"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
file="/root/.aria2"
aria2_conf="/root/.aria2/aria2.conf"
aria2_log="/root/.aria2/aria2.log"
Folder="/usr/local/aria2"
aria2c="/usr/bin/aria2c"
Crontab_file="/usr/bin/crontab"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[訊息]${Font_color_suffix}"
Error="${Red_font_prefix}[錯誤]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 目前非ROOT帳號(或沒有ROOT權限)，無法繼續操作，請更換ROOT帳號或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 指令獲取臨時ROOT權限（執行後可能會提示輸入目前帳號的密碼）。" && exit 1
}
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
	[[ ! -e ${aria2c} ]] && echo -e "${Error} Aria2 沒有安裝，請檢查 !" && exit 1
	[[ ! -e ${aria2_conf} ]] && echo -e "${Error} Aria2 設定檔案不存在，請檢查 !" && [[ $1 != "un" ]] && exit 1
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
	PID=`ps -ef| grep "aria2c"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
check_new_ver(){
	aria2_new_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/q3aql/aria2-static-builds/releases | grep -o '"tag_name": ".*"' |head -n 1| sed 's/"//g;s/v//g' | sed 's/tag_name: //g')
	if [[ -z ${aria2_new_ver} ]]; then
		echo -e "${Error} Aria2 最新版本獲取失敗，請手動獲取最新版本號[ https://github.com/q3aql/aria2-static-builds/releases ]"
		stty erase '^H' && read -p "請輸入版本號 [ 格式如 1.33.1 ] :" aria2_new_ver
		[[ -z "${aria2_new_ver}" ]] && echo "取消..." && exit 1
	else
		echo -e "${Info} 檢測到 Aria2 最新版本為 [ ${aria2_new_ver} ]"
	fi
}
check_ver_comparison(){
	aria2_now_ver=$(${aria2c} -v|head -n 1|awk '{print $3}')
	[[ -z ${aria2_now_ver} ]] && echo -e "${Error} Brook 目前版本獲取失敗 !" && exit 1
	if [[ "${aria2_now_ver}" != "${aria2_new_ver}" ]]; then
		echo -e "${Info} 發現 Aria2 已有新版本 [ ${aria2_new_ver} ](目前版本：${aria2_now_ver})"
		stty erase '^H' && read -p "是否更新(會中斷目前下載任務，請注意) ? [Y/n] :" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			Download_aria2 "update"
			Start_aria2
		fi
	else
		echo -e "${Info} 目前 Aria2 已是最新版本 [ ${aria2_new_ver} ]" && exit 1
	fi
}
Download_aria2(){
	update_dl=$1
	cd "/usr/local"
	#echo -e "${bit}"
	if [[ ${bit} == "armv7l" ]]; then
		wget -N --no-check-certificate "https://github.com/q3aql/aria2-static-builds/releases/download/v${aria2_new_ver}/aria2-${aria2_new_ver}-linux-gnu-arm-rbpi-build1.tar.bz2"
		Aria2_Name="aria2-${aria2_new_ver}-linux-gnu-arm-rbpi-build1"
	elif [[ ${bit} == "x86_64" ]]; then
		wget -N --no-check-certificate "https://github.com/q3aql/aria2-static-builds/releases/download/v${aria2_new_ver}/aria2-${aria2_new_ver}-linux-gnu-64bit-build1.tar.bz2"
		Aria2_Name="aria2-${aria2_new_ver}-linux-gnu-64bit-build1"
	else
		wget -N --no-check-certificate "https://github.com/q3aql/aria2-static-builds/releases/download/v${aria2_new_ver}/aria2-${aria2_new_ver}-linux-gnu-32bit-build1.tar.bz2"
		Aria2_Name="aria2-${aria2_new_ver}-linux-gnu-32bit-build1"
	fi
	[[ ! -e "${Aria2_Name}.tar.bz2" ]] && echo -e "${Error} Aria2 壓縮包下載失敗 !" && exit 1
	tar jxvf "${Aria2_Name}.tar.bz2"
	[[ ! -e "/usr/local/${Aria2_Name}" ]] && echo -e "${Error} Aria2 解壓失敗 !" && rm -rf "${Aria2_Name}.tar.bz2" && exit 1
	[[ ${update_dl} = "update" ]] && rm -rf "${Folder}"
	mv "/usr/local/${Aria2_Name}" "${Folder}"
	[[ ! -e "${Folder}" ]] && echo -e "${Error} Aria2 資料夾重新命名失敗 !" && rm -rf "${Aria2_Name}.tar.bz2" && rm -rf "/usr/local/${Aria2_Name}" && exit 1
	rm -rf "${Aria2_Name}.tar.bz2"
	cd "${Folder}"
	make install
	[[ ! -e ${aria2c} ]] && echo -e "${Error} Aria2 主程式安裝失敗！" && rm -rf "${Folder}" && exit 1
	chmod +x aria2c
	echo -e "${Info} Aria2 主程式安裝完畢！開始下載設定檔案..."
}
Download_aria2_conf(){
	mkdir "${file}" && cd "${file}"
	wget --no-check-certificate -N "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/other/Aria2/aria2.conf"
	[[ ! -s "aria2.conf" ]] && echo -e "${Error} Aria2 設定檔案下載失敗 !" && rm -rf "${file}" && exit 1
	wget --no-check-certificate -N "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/other/Aria2/dht.dat"
	[[ ! -s "dht.dat" ]] && echo -e "${Error} Aria2 DHT檔案下載失敗 !" && rm -rf "${file}" && exit 1
	echo '' > aria2.session
	sed -i 's/^rpc-secret=DOUBIToyo/rpc-secret='$(date +%s%N | md5sum | head -c 20)'/g' ${aria2_conf}
}
Service_aria2(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/other/aria2_centos -O /etc/init.d/aria2; then
			echo -e "${Error} Aria2服務 管理腳本下載失敗 !" && exit 1
		fi
		chmod +x /etc/init.d/aria2
		chkconfig --add aria2
		chkconfig aria2 on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/other/aria2_debian -O /etc/init.d/aria2; then
			echo -e "${Error} Aria2服務 管理腳本下載失敗 !" && exit 1
		fi
		chmod +x /etc/init.d/aria2
		update-rc.d -f aria2 defaults
	fi
	echo -e "${Info} Aria2服務 管理腳本下載完成 !"
}
Installation_dependency(){
	if [[ ${release} = "centos" ]]; then
		yum update
		yum -y groupinstall "Development Tools"
		yum install vim -y
	else
		apt-get update
		apt-get install vim build-essential -y
	fi
}
Install_aria2(){
	check_root
	[[ -e ${aria2c} ]] && echo -e "${Error} Aria2 已安裝，請檢查 !" && exit 1
	check_sys
	echo -e "${Info} 開始安裝/設定 依賴..."
	Installation_dependency
	echo -e "${Info} 開始下載/安裝 主程式..."
	check_new_ver
	Download_aria2
	echo -e "${Info} 開始下載/安裝 設定檔案..."
	Download_aria2_conf
	echo -e "${Info} 開始下載/安裝 服務腳本(init)..."
	Service_aria2
	Read_config
	aria2_RPC_port=${aria2_port}
	echo -e "${Info} 開始設定 iptables防火牆..."
	Set_iptables
	echo -e "${Info} 開始添加 iptables防火牆規則..."
	Add_iptables
	echo -e "${Info} 開始儲存 iptables防火牆規則..."
	Save_iptables
	echo -e "${Info} 所有步驟 安裝完畢，開始啟動..."
	Start_aria2
}
Start_aria2(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} Aria2 正在執行，請檢查 !" && exit 1
	/etc/init.d/aria2 start
}
Stop_aria2(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} Aria2 沒有執行，請檢查 !" && exit 1
	/etc/init.d/aria2 stop
}
Restart_aria2(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/aria2 stop
	/etc/init.d/aria2 start
}
Set_aria2(){
	check_installed_status
	echo && echo -e "你要做什麼？
 ${Green_font_prefix}1.${Font_color_suffix}  修改 Aria2 RPC密碼
 ${Green_font_prefix}2.${Font_color_suffix}  修改 Aria2 RPC埠
 ${Green_font_prefix}3.${Font_color_suffix}  修改 Aria2 檔案下載位置
 ${Green_font_prefix}4.${Font_color_suffix}  修改 Aria2 密碼+埠+檔案下載位置
 ${Green_font_prefix}5.${Font_color_suffix}  手動 打開設定檔案修改" && echo
	stty erase '^H' && read -p "(預設: 取消):" aria2_modify
	[[ -z "${aria2_modify}" ]] && echo "已取消..." && exit 1
	if [[ ${aria2_modify} == "1" ]]; then
		Set_aria2_RPC_passwd
	elif [[ ${aria2_modify} == "2" ]]; then
		Set_aria2_RPC_port
	elif [[ ${aria2_modify} == "3" ]]; then
		Set_aria2_RPC_dir
	elif [[ ${aria2_modify} == "4" ]]; then
		Set_aria2_RPC_passwd_port_dir
	elif [[ ${aria2_modify} == "5" ]]; then
		Set_aria2_vim_conf
	else
		echo -e "${Error} 請輸入正確的數位(1-5)" && exit 1
	fi
}
Set_aria2_RPC_passwd(){
	read_123=$1
	if [[ ${read_123} != "1" ]]; then
		Read_config
	fi
	if [[ -z "${aria2_passwd}" ]]; then
		aria2_passwd_1="空(沒有檢測到設定，可能手動刪除或注釋了)"
	else
		aria2_passwd_1=${aria2_passwd}
	fi
	echo -e "請輸入要設置的 Aria2 RPC密碼(舊密碼為：${Green_font_prefix}${aria2_passwd_1}${Font_color_suffix})"
	stty erase '^H' && read -p "(預設密碼: 隨機生成 密碼請不要包含等號 = 和井號 #):" aria2_RPC_passwd
	echo
	[[ -z "${aria2_RPC_passwd}" ]] && aria2_RPC_passwd=$(date +%s%N | md5sum | head -c 20)
	if [[ "${aria2_passwd}" != "${aria2_RPC_passwd}" ]]; then
		if [[ -z "${aria2_passwd}" ]]; then
			echo -e "\nrpc-secret=${aria2_RPC_passwd}" >> ${aria2_conf}
			if [[ $? -eq 0 ]];then
				echo -e "${Info} 密碼修改成功！新密碼為：${Green_font_prefix}${aria2_RPC_passwd}${Font_color_suffix}(因為找不到舊設定參數，所以自動加入設定檔案底部)"
				if [[ ${read_123} != "1" ]]; then
					Restart_aria2
				fi
			else 
				echo -e "${Error} 密碼修改失敗！舊密碼為：${Green_font_prefix}${aria2_passwd}${Font_color_suffix}"
			fi
		else
			sed -i 's/^rpc-secret='${aria2_passwd}'/rpc-secret='${aria2_RPC_passwd}'/g' ${aria2_conf}
			if [[ $? -eq 0 ]];then
				echo -e "${Info} 密碼修改成功！新密碼為：${Green_font_prefix}${aria2_RPC_passwd}${Font_color_suffix}"
				if [[ ${read_123} != "1" ]]; then
					Restart_aria2
				fi
			else 
				echo -e "${Error} 密碼修改失敗！舊密碼為：${Green_font_prefix}${aria2_passwd}${Font_color_suffix}"
			fi
		fi
	else
		echo -e "${Error} 新密碼與舊密碼一致，取消..."
	fi
}
Set_aria2_RPC_port(){
	read_123=$1
	if [[ ${read_123} != "1" ]]; then
		Read_config
	fi
	if [[ -z "${aria2_port}" ]]; then
		aria2_port_1="空(沒有檢測到設定，可能手動刪除或注釋了)"
	else
		aria2_port_1=${aria2_port}
	fi
	echo -e "請輸入要設置的 Aria2 RPC埠(舊埠為：${Green_font_prefix}${aria2_port_1}${Font_color_suffix})"
	stty erase '^H' && read -p "(預設埠: 6800):" aria2_RPC_port
	echo
	[[ -z "${aria2_RPC_port}" ]] && aria2_RPC_port="6800"
	if [[ "${aria2_port}" != "${aria2_RPC_port}" ]]; then
		if [[ -z "${aria2_port}" ]]; then
			echo -e "\nrpc-listen-port=${aria2_RPC_port}" >> ${aria2_conf}
			if [[ $? -eq 0 ]];then
				echo -e "${Info} 埠修改成功！新埠為：${Green_font_prefix}${aria2_RPC_port}${Font_color_suffix}(因為找不到舊設定參數，所以自動加入設定檔案底部)"
				Del_iptables
				Add_iptables
				Save_iptables
				if [[ ${read_123} != "1" ]]; then
					Restart_aria2
				fi
			else 
				echo -e "${Error} 埠修改失敗！舊埠為：${Green_font_prefix}${aria2_port}${Font_color_suffix}"
			fi
		else
			sed -i 's/^rpc-listen-port='${aria2_port}'/rpc-listen-port='${aria2_RPC_port}'/g' ${aria2_conf}
			if [[ $? -eq 0 ]];then
				echo -e "${Info} 埠修改成功！新密碼為：${Green_font_prefix}${aria2_RPC_port}${Font_color_suffix}"
				Del_iptables
				Add_iptables
				Save_iptables
				if [[ ${read_123} != "1" ]]; then
					Restart_aria2
				fi
			else 
				echo -e "${Error} 埠修改失敗！舊密碼為：${Green_font_prefix}${aria2_port}${Font_color_suffix}"
			fi
		fi
	else
		echo -e "${Error} 新埠與舊埠一致，取消..."
	fi
}
Set_aria2_RPC_dir(){
	read_123=$1
	if [[ ${read_123} != "1" ]]; then
		Read_config
	fi
	if [[ -z "${aria2_dir}" ]]; then
		aria2_dir_1="空(沒有檢測到設定，可能手動刪除或注釋了)"
	else
		aria2_dir_1=${aria2_dir}
	fi
	echo -e "請輸入要設置的 Aria2 檔案下載位置(舊位置為：${Green_font_prefix}${aria2_dir_1}${Font_color_suffix})"
	stty erase '^H' && read -p "(預設位置: /usr/local/caddy/www/aria2/Download):" aria2_RPC_dir
	[[ -z "${aria2_RPC_dir}" ]] && aria2_RPC_dir="/usr/local/caddy/www/aria2/Download"
	echo
	if [[ -d "${aria2_RPC_dir}" ]]; then
		if [[ "${aria2_dir}" != "${aria2_RPC_dir}" ]]; then
			if [[ -z "${aria2_dir}" ]]; then
				echo -e "\ndir=${aria2_RPC_dir}" >> ${aria2_conf}
				if [[ $? -eq 0 ]];then
					echo -e "${Info} 位置修改成功！新位置為：${Green_font_prefix}${aria2_RPC_dir}${Font_color_suffix}(因為找不到舊設定參數，所以自動加入設定檔案底部)"
					if [[ ${read_123} != "1" ]]; then
						Restart_aria2
					fi
				else 
					echo -e "${Error} 位置修改失敗！舊位置為：${Green_font_prefix}${aria2_dir}${Font_color_suffix}"
				fi
			else
				aria2_dir_2=$(echo "${aria2_dir}"|sed 's/\//\\\//g')
				aria2_RPC_dir_2=$(echo "${aria2_RPC_dir}"|sed 's/\//\\\//g')
				sed -i 's/^dir='${aria2_dir_2}'/dir='${aria2_RPC_dir_2}'/g' ${aria2_conf}
				if [[ $? -eq 0 ]];then
					echo -e "${Info} 位置修改成功！新位置為：${Green_font_prefix}${aria2_RPC_dir}${Font_color_suffix}"
					if [[ ${read_123} != "1" ]]; then
						Restart_aria2
					fi
				else 
					echo -e "${Error} 位置修改失敗！舊位置為：${Green_font_prefix}${aria2_dir}${Font_color_suffix}"
				fi
			fi
		else
			echo -e "${Error} 新位置與舊位置一致，取消..."
		fi
	else
		echo -e "${Error} 新位置資料夾不存在，請檢查！新位置為：${Green_font_prefix}${aria2_RPC_dir}${Font_color_suffix}"
	fi
}
Set_aria2_RPC_passwd_port_dir(){
	Read_config
	Set_aria2_RPC_passwd "1"
	Set_aria2_RPC_port "1"
	Set_aria2_RPC_dir "1"
	Restart_aria2
}
Set_aria2_vim_conf(){
	Read_config
	aria2_port_old=${aria2_port}
	echo -e "${Tip} 手動修改設定檔案須知（VIM 編輯器）：
${Green_font_prefix}1.${Font_color_suffix} 設定檔案中含有中文注釋，如果你的伺服器或SSH工具不支援中文現在，將會亂碼(請本機編輯)。
${Green_font_prefix}2.${Font_color_suffix} 打開設定檔案後，按 ${Green_font_prefix}I鍵${Font_color_suffix} 進入編輯模式(左下角顯示 ${Green_font_prefix}-- INSERT --${Font_color_suffix})，然後就可以編輯檔案了，
   編輯檔案完成後，按 ${Green_font_prefix}Esc鍵${Font_color_suffix} 退出編輯模式，然後輸入 ${Green_font_prefix}:wq${Font_color_suffix} (半形 小寫)回車，即儲存並退出。
${Green_font_prefix}3.${Font_color_suffix} 如果你不想要儲存，那麼按 ${Green_font_prefix}Esc鍵${Font_color_suffix} 退出編輯模式，然後輸入 ${Green_font_prefix}:q!${Font_color_suffix} (半形 小寫)回車，即不儲存退出。
${Green_font_prefix}4.${Font_color_suffix} 如果你打算在本機編輯設定檔案，那麼設定檔案位置： ${Green_font_prefix}/root/.aria2/aria2.conf${Font_color_suffix} (注意是隱藏目錄) 。" && echo
	stty erase '^H' && read -p "如果理解 VIM 使用方法，請按任意鍵繼續，如要取消請使用 Ctrl+C 。" var
	vim ${aria2_conf}
	Read_config
	if [[ ${aria2_port_old} != ${aria2_port} ]]; then
		aria2_RPC_port=${aria2_port}
		aria2_port=${aria2_port_old}
		Del_iptables
		Add_iptables
		Save_iptables
	fi
	Restart_aria2
}
Read_config(){
	status_type=$1
	if [[ ! -e ${aria2_conf} ]]; then
		if [[ ${status_type} != "un" ]]; then
			echo -e "${Error} Aria2 設定檔案不存在 !" && exit 1
		fi
	else
		conf_text=$(cat ${aria2_conf}|grep -v '#')
		aria2_dir=$(echo -e "${conf_text}"|grep "dir="|awk -F "=" '{print $NF}')
		aria2_port=$(echo -e "${conf_text}"|grep "rpc-listen-port="|awk -F "=" '{print $NF}')
		aria2_passwd=$(echo -e "${conf_text}"|grep "rpc-secret="|awk -F "=" '{print $NF}')
	fi
	
}
View_Aria2(){
	check_installed_status
	Read_config
	ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ip}" ]]; then
		ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ip}" ]]; then
				ip="VPS_IP(外網IP檢測失敗)"
			fi
		fi
	fi
	[[ -z "${aria2_dir}" ]] && aria2_dir="找不到設定參數"
	[[ -z "${aria2_port}" ]] && aria2_port="找不到設定參數"
	[[ -z "${aria2_passwd}" ]] && aria2_passwd="找不到設定參數(或無密碼)"
	clear
	echo -e "\nAria2 簡單設定訊息：\n
 地址\t: ${Green_font_prefix}${ip}${Font_color_suffix}
 埠\t: ${Green_font_prefix}${aria2_port}${Font_color_suffix}
 密碼\t: ${Green_font_prefix}${aria2_passwd}${Font_color_suffix}
 目錄\t: ${Green_font_prefix}${aria2_dir}${Font_color_suffix}\n"
}
View_Log(){
	[[ ! -e ${aria2_log} ]] && echo -e "${Error} Aria2 日誌檔案不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 終止查看日誌" && echo
	tail -f ${aria2_log}
}
Update_bt_tracker(){
	check_installed_status
	check_crontab_installed_status
	crontab_update_status=$(crontab -l|grep "aria2.sh update-bt-tracker")
	if [[ -z "${crontab_update_status}" ]]; then
		echo && echo -e "目前自動更新模式: ${Red_font_prefix}未開啟${Font_color_suffix}" && echo
		echo -e "確定要開啟 ${Green_font_prefix}Aria2 自動更新 BT-Tracker伺服器${Font_color_suffix} 功能嗎？(一般情況下會加強BT下載效果)[Y/n]"
		stty erase '^H' && read -p "注意：該功能會定時重啟 Aria2！(預設: y):" crontab_update_status_ny
		[[ -z "${crontab_update_status_ny}" ]] && crontab_update_status_ny="y"
		if [[ ${crontab_update_status_ny} == [Yy] ]]; then
			crontab_update_start
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo && echo -e "目前自動更新模式: ${Green_font_prefix}已開啟${Font_color_suffix}" && echo
		echo -e "確定要關閉 ${Red_font_prefix}Aria2 自動更新 BT-Tracker伺服器${Font_color_suffix} 功能嗎？(一般情況下會加強BT下載效果)[y/N]"
		stty erase '^H' && read -p "注意：該功能會定時重啟 Aria2！(預設: n):" crontab_update_status_ny
		[[ -z "${crontab_update_status_ny}" ]] && crontab_update_status_ny="n"
		if [[ ${crontab_update_status_ny} == [Yy] ]]; then
			crontab_update_stop
		else
			echo && echo "	已取消..." && echo
		fi
	fi
}
crontab_update_start(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/aria2.sh update-bt-tracker/d" "$file_1/crontab.bak"
	echo -e "\n0 3 * * * /bin/bash $file_1/aria2.sh update-bt-tracker" >> "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -f "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "aria2.sh update-bt-tracker")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} Aria2 自動更新 BT-Tracker伺服器 開啟失敗 !" && exit 1
	else
		echo -e "${Info} Aria2 自動更新 BT-Tracker伺服器 開啟成功 !"
		Update_bt_tracker_cron
	fi
}
crontab_update_stop(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/aria2.sh update-bt-tracker/d" "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -f "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "aria2.sh update-bt-tracker")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} Aria2 自動更新 BT-Tracker伺服器 停止失敗 !" && exit 1
	else
		echo -e "${Info} Aria2 自動更新 BT-Tracker伺服器 停止成功 !"
	fi
}
Update_bt_tracker_cron(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/aria2 stop
	bt_tracker_list=$(wget -qO- https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt |awk NF|sed ":a;N;s/\n/,/g;ta")
	if [ -z "`grep "bt-tracker" ${aria2_conf}`" ]; then
		sed -i '$a bt-tracker='${bt_tracker_list} "${aria2_conf}"
		echo -e "${Info} 添加成功..."
	else
		sed -i "s@bt-tracker.*@bt-tracker=$bt_tracker_list@g" "${aria2_conf}"
		echo -e "${Info} 更新成功..."
	fi
	/etc/init.d/aria2 start
}
Update_aria2(){
	check_installed_status
	check_new_ver
	check_ver_comparison
}
Uninstall_aria2(){
	check_installed_status "un"
	echo "確定要移除 Aria2 ? (y/N)"
	echo
	stty erase '^H' && read -p "(預設: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		crontab -l > "$file_1/crontab.bak"
		sed -i "/aria2.sh/d" "$file_1/crontab.bak"
		crontab "$file_1/crontab.bak"
		rm -f "$file_1/crontab.bak"
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config "un"
		Del_iptables
		Save_iptables
		cd "${Folder}"
		make uninstall
		cd ..
		rm -rf "${aria2c}"
		rm -rf "${Folder}"
		rm -rf "${file}"
		if [[ ${release} = "centos" ]]; then
			chkconfig --del aria2
		else
			update-rc.d -f aria2 remove
		fi
		rm -rf "/etc/init.d/aria2"
		echo && echo "Aria2 移除完成 !" && echo
	else
		echo && echo "移除已取消..." && echo
	fi
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${aria2_RPC_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${aria2_RPC_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${aria2_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${aria2_port} -j ACCEPT
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
	sh_new_ver=$(wget --no-check-certificate -qO- "https://softs.loan/Bash/aria2.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="softs"
	[[ -z ${sh_new_ver} ]] && sh_new_ver=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/aria2.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 檢測最新版本失敗 !" && exit 0
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "發現新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
		stty erase '^H' && read -p "(預設: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			if [[ -e "/etc/init.d/aria2" ]]; then
				rm -rf /etc/init.d/aria2
				Service_aria2
			fi
			if [[ ${sh_new_type} == "softs" ]]; then
				wget -N --no-check-certificate https://softs.loan/Bash/aria2.sh && chmod +x aria2.sh
			else
				wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/aria2.sh && chmod +x aria2.sh
			fi
			echo -e "腳本已更新為最新版本[ ${sh_new_ver} ] !"
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo -e "目前已是最新版本[ ${sh_new_ver} ] !"
	fi
}
action=$1
if [[ "${action}" == "update-bt-tracker" ]]; then
	Update_bt_tracker_cron
else
echo && echo -e " Aria2 一鍵安裝管理腳本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/shell-jc4 --
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升級腳本
————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安裝 Aria2
 ${Green_font_prefix} 2.${Font_color_suffix} 更新 Aria2
 ${Green_font_prefix} 3.${Font_color_suffix} 移除 Aria2
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 啟動 Aria2
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 Aria2
 ${Green_font_prefix} 6.${Font_color_suffix} 重啟 Aria2
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 修改 設定檔案
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 設定訊息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 日誌訊息
 ${Green_font_prefix}10.${Font_color_suffix} 設定 自動更新 BT-Tracker伺服器
————————————" && echo
if [[ -e ${aria2c} ]]; then
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
	Install_aria2
	;;
	2)
	Update_aria2
	;;
	3)
	Uninstall_aria2
	;;
	4)
	Start_aria2
	;;
	5)
	Stop_aria2
	;;
	6)
	Restart_aria2
	;;
	7)
	Set_aria2
	;;
	8)
	View_Aria2
	;;
	9)
	View_Log
	;;
	10)
	Update_bt_tracker
	;;
	*)
	echo "請輸入正確數字 [0-10]"
	;;
esac
fi
