#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6+/Debian 7+/Ubuntu 14.04+
#	Description: ShadowsocksR Status
#	Version: 1.0.5
#	Author: Toyo
#=================================================

sh_ver="1.0.5"
Timeout="10"
Test_URL="https://www.bing.com"
Web_file="/usr/local/SSRStatus"
SSR_folder="/root/shadowsocksr/shadowsocks"
filepath=$(cd "$(dirname "$0")"; pwd)
file=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
log_file="${file}/ssr_status.log"
config_file="${file}/ssr_status.conf"
JSON_file="/usr/local/SSRStatus/json/stats.json"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[訊息]${Font_color_suffix}" && Error="${Red_font_prefix}[錯誤]${Font_color_suffix}" && Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

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
check_installed_server_status(){
	[[ ! -e "${Web_file}" ]] && echo -e "${Error} SSRStatus Web網頁檔案沒有安裝，請檢查 !" && exit 1
}
set_config_ip(){
	echo "請輸入 ShadowsocksR 帳號伺服器公網IP"
	stty erase '^H' && read -p "(預設取消):" ip
	[[ -z "${ip}" ]] && echo "已取消..." && exit 1
	echo && echo -e "	I   P : ${Red_font_prefix}${ip}${Font_color_suffix}" && echo
}
set_config_port(){
	while true
	do
	echo -e "請輸入 ShadowsocksR 帳號埠"
	stty erase '^H' && read -p "(預設: 2333):" port
	[[ -z "$port" ]] && port="2333"
	expr ${port} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${port} -ge 1 ]] && [[ ${port} -le 65535 ]]; then
			echo && echo -e "	埠 : ${Red_font_prefix}${port}${Font_color_suffix}" && echo
			break
		else
			echo -e "${Error} 請輸入正確的數位！"
		fi
	else
		echo -e "${Error} 請輸入正確的數位！"
	fi
	done
}
set_config_password(){
	echo "請輸入 ShadowsocksR 帳號密碼"
	stty erase '^H' && read -p "(預設: doub.io):" passwd
	[[ -z "${passwd}" ]] && passwd="doub.io"
	echo && echo -e "	密碼 : ${Red_font_prefix}${passwd}${Font_color_suffix}" && echo
}
set_config_method(){
	echo -e "請選擇要設置的ShadowsocksR帳號 加密方式
 ${Green_font_prefix} 1.${Font_color_suffix} none
 
 ${Green_font_prefix} 2.${Font_color_suffix} rc4
 ${Green_font_prefix} 3.${Font_color_suffix} rc4-md5
 ${Green_font_prefix} 4.${Font_color_suffix} rc4-md5-6
 
 ${Green_font_prefix} 5.${Font_color_suffix} aes-128-ctr
 ${Green_font_prefix} 6.${Font_color_suffix} aes-192-ctr
 ${Green_font_prefix} 7.${Font_color_suffix} aes-256-ctr
 
 ${Green_font_prefix} 8.${Font_color_suffix} aes-128-cfb
 ${Green_font_prefix} 9.${Font_color_suffix} aes-192-cfb
 ${Green_font_prefix}10.${Font_color_suffix} aes-256-cfb
 
 ${Green_font_prefix}11.${Font_color_suffix} aes-128-cfb8
 ${Green_font_prefix}12.${Font_color_suffix} aes-192-cfb8
 ${Green_font_prefix}13.${Font_color_suffix} aes-256-cfb8
 
 ${Green_font_prefix}14.${Font_color_suffix} salsa20
 ${Green_font_prefix}15.${Font_color_suffix} chacha20
 ${Green_font_prefix}16.${Font_color_suffix} chacha20-ietf
 ${Tip} salsa20/chacha20-*系列加密方式，需要額外安裝依賴 libsodium ，否則會無法啟動ShadowsocksR !" && echo
	stty erase '^H' && read -p "(預設: 5. aes-128-ctr):" method
	[[ -z "${method}" ]] && method="5"
	if [[ ${method} == "1" ]]; then
		method="none"
	elif [[ ${method} == "2" ]]; then
		method="rc4"
	elif [[ ${method} == "3" ]]; then
		method="rc4-md5"
	elif [[ ${method} == "4" ]]; then
		method="rc4-md5-6"
	elif [[ ${method} == "5" ]]; then
		method="aes-128-ctr"
	elif [[ ${method} == "6" ]]; then
		method="aes-192-ctr"
	elif [[ ${method} == "7" ]]; then
		method="aes-256-ctr"
	elif [[ ${method} == "8" ]]; then
		method="aes-128-cfb"
	elif [[ ${method} == "9" ]]; then
		method="aes-192-cfb"
	elif [[ ${method} == "10" ]]; then
		method="aes-256-cfb"
	elif [[ ${method} == "11" ]]; then
		method="aes-128-cfb8"
	elif [[ ${method} == "12" ]]; then
		method="aes-192-cfb8"
	elif [[ ${method} == "13" ]]; then
		method="aes-256-cfb8"
	elif [[ ${method} == "14" ]]; then
		method="salsa20"
	elif [[ ${method} == "15" ]]; then
		method="chacha20"
	elif [[ ${method} == "16" ]]; then
		method="chacha20-ietf"
	else
		method="aes-128-ctr"
	fi
	echo && echo ${Separator_1} && echo -e "	加密 : ${Red_font_prefix}${method}${Font_color_suffix}" && echo ${Separator_1} && echo
}
set_config_protocol(){
	echo -e "請選擇ShadowsocksR帳號 協議插件
 ${Green_font_prefix}1.${Font_color_suffix} origin
 ${Green_font_prefix}2.${Font_color_suffix} auth_sha1_v4
 ${Green_font_prefix}3.${Font_color_suffix} auth_aes128_md5
 ${Green_font_prefix}4.${Font_color_suffix} auth_aes128_sha1
 ${Green_font_prefix}5.${Font_color_suffix} auth_chain_a" && echo
	stty erase '^H' && read -p "(預設: 2. auth_sha1_v4):" protocol
	[[ -z "${protocol}" ]] && protocol="2"
	if [[ ${protocol} == "1" ]]; then
		protocol="origin"
	elif [[ ${protocol} == "2" ]]; then
		protocol="auth_sha1_v4"
	elif [[ ${protocol} == "3" ]]; then
		protocol="auth_aes128_md5"
	elif [[ ${protocol} == "4" ]]; then
		protocol="auth_aes128_sha1"
	elif [[ ${protocol} == "5" ]]; then
		protocol="auth_chain_a"
	else
		protocol="auth_sha1_v4"
	fi
	echo && echo -e "	協議 : ${Red_font_prefix}${protocol}${Font_color_suffix}" && echo
}
set_config_obfs(){
	echo -e "請選擇ShadowsocksR帳號 混淆插件
 ${Green_font_prefix}1.${Font_color_suffix} plain
 ${Green_font_prefix}2.${Font_color_suffix} http_simple
 ${Green_font_prefix}3.${Font_color_suffix} http_post
 ${Green_font_prefix}4.${Font_color_suffix} random_head
 ${Green_font_prefix}5.${Font_color_suffix} tls1.2_ticket_auth" && echo
	stty erase '^H' && read -p "(預設: 5. tls1.2_ticket_auth):" obfs
	[[ -z "${obfs}" ]] && obfs="5"
	if [[ ${obfs} == "1" ]]; then
		obfs="plain"
	elif [[ ${obfs} == "2" ]]; then
		obfs="http_simple"
	elif [[ ${obfs} == "3" ]]; then
		obfs="http_post"
	elif [[ ${obfs} == "4" ]]; then
		obfs="random_head"
	elif [[ ${obfs} == "5" ]]; then
		obfs="tls1.2_ticket_auth"
	else
		obfs="tls1.2_ticket_auth"
	fi
	echo && echo -e "	混淆 : ${Red_font_prefix}${obfs}${Font_color_suffix}" && echo
}
set_config_like(){
	echo "請輸入 ShadowsocksR 的連結(SS/SSR連結皆可，如 ss://xxxx ssr://xxxx)"
	stty erase '^H' && read -p "(預設回車取消):" Like
	[[ -z "${Like}" ]] && echo "已取消..." && exit 1
	echo && echo -e "	連結 : ${Red_font_prefix}${Like}${Font_color_suffix}" && echo
}
set_config_user(){
	echo -e "請輸入選擇輸入方式
 ${Green_font_prefix}1.${Font_color_suffix} 輸入ShadowsocksR帳號全部訊息(Shadowsocks原版也可以)
 ${Green_font_prefix}2.${Font_color_suffix} 輸入ShadowsocksR帳號的 SSR連結(Shadowsocks原版也可以)"
	stty erase '^H' && read -p "(預設:2):" enter_type
	[[ -z "${enter_type}" ]] && enter_type="2"
	if [[ ${enter_type} == "1" ]]; then
		echo -e "下面依次開始輸入要檢測可用性的 ShadowsocksR帳號訊息。" && echo
		set_config_ip
		set_config_port
		set_config_password
		set_config_method
		set_config_protocol
		set_config_obfs
		return 1
	elif [[ ${enter_type} == "2" ]]; then
		set_config_like
		return 2
	else
		set_config_like
		return 2
	fi
}
set_config_name(){
	echo "請輸入 ShadowsocksR 帳號的名稱(用於區分，取個名字，可重複)"
	stty erase '^H' && read -p "(預設取消):" Config_Name
	[[ -z "${Config_Name}" ]] && echo "已取消..." && exit 1
	echo && echo -e "	名稱 : ${Red_font_prefix}${Config_Name}${Font_color_suffix}" && echo
}
set_config_location(){
	echo "請輸入 ShadowsocksR 帳號的位置(用於區分，可重複)"
	stty erase '^H' && read -p "(預設取消):" Config_Location
	[[ -z "${Config_Location}" ]] && echo "已取消..." && exit 1
	echo && echo -e "	位置 : ${Red_font_prefix}${Config_Location}${Font_color_suffix}" && echo
}
Set_server(){
	echo -e "請輸入 SSRStatus 網站要設置的 域名[server]
預設為本機IP為域名，例如輸入: toyoo.ml，如果要使用本機IP，請留空直接回車"
	stty erase '^H' && read -p "(預設: 本機IP):" server_s
	[[ -z "$server_s" ]] && server_s=""
	
	echo && echo -e "	IP/域名[server]: ${Red_background_prefix} ${server_s} ${Font_color_suffix}" && echo
}
Set_server_port(){
	while true
		do
		echo -e "請輸入 SSRStatus 網站要設置的 域名/IP的埠[1-65535]（如果是域名的話，一般建議用 http 80 埠）"
		stty erase '^H' && read -p "(預設: 8888):" server_port_s
		[[ -z "$server_port_s" ]] && server_port_s="8888"
		expr ${server_port_s} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${server_port_s} -ge 1 ]] && [[ ${server_port_s} -le 65535 ]]; then
				echo && echo -e "	IP/域名[server]: ${Red_background_prefix} ${server_port_s} ${Font_color_suffix}" && echo
				break
			else
				echo "輸入錯誤, 請輸入正確的埠。"
			fi
		else
			echo "輸入錯誤, 請輸入正確的埠。"
		fi
	done
}
Set_crontab(){
	echo -e "請選擇你要設置的ShadowsocksR帳號檢測時間間隔（如帳號很多，請不要設定時間間隔過小）
 ${Green_font_prefix}1.${Font_color_suffix} 5分鐘
 ${Green_font_prefix}2.${Font_color_suffix} 10分鐘
 ${Green_font_prefix}3.${Font_color_suffix} 20分鐘
 ${Green_font_prefix}4.${Font_color_suffix} 30分鐘
 ${Green_font_prefix}5.${Font_color_suffix} 40分鐘
 ${Green_font_prefix}6.${Font_color_suffix} 50分鐘
 ${Green_font_prefix}7.${Font_color_suffix} 1小時
 ${Green_font_prefix}8.${Font_color_suffix} 2小時
 ${Green_font_prefix}9.${Font_color_suffix} 自訂輸入" && echo
	stty erase '^H' && read -p "(預設: 2. 10分鐘):" Crontab_time
	[[ -z "${Crontab_time}" ]] && Crontab_time="2"
	if [[ ${Crontab_time} == "1" ]]; then
		Crontab_time="*/5 * * * *"
	elif [[ ${Crontab_time} == "2" ]]; then
		Crontab_time="*/10 * * * *"
	elif [[ ${Crontab_time} == "3" ]]; then
		Crontab_time="*/20 * * * *"
	elif [[ ${Crontab_time} == "4" ]]; then
		Crontab_time="*/30 * * * *"
	elif [[ ${Crontab_time} == "5" ]]; then
		Crontab_time="*/40 * * * *"
	elif [[ ${Crontab_time} == "6" ]]; then
		Crontab_time="*/50 * * * *"
	elif [[ ${Crontab_time} == "7" ]]; then
		Crontab_time="0 * * * *"
	elif [[ ${Crontab_time} == "8" ]]; then
		Crontab_time="0 */2 * * *"
	elif [[ ${Crontab_time} == "9" ]]; then
		Set_crontab_customize
	else
		Crontab_time="*/10 * * * *"
	fi
	echo && echo -e "	間隔時間 : ${Red_font_prefix}${Crontab_time}${Font_color_suffix}" && echo
	Add_Crontab
}
Set_crontab_customize(){
	echo -e "請輸入ShadowsocksR帳號檢測時間間隔（如帳號很多，請不要設定時間間隔過小）
 === 格式說明 ===
 * * * * * 分別對應 分鐘 小時 日份 月份 星期
 ${Green_font_prefix} */10 * * * * ${Font_color_suffix} 代表每10分鐘 檢測一次
 ${Green_font_prefix} 0 */2 * * * ${Font_color_suffix} 代表每2小時的0分 檢測一次
 ${Green_font_prefix} 10 * * * * ${Font_color_suffix} 代表每小時的第10分 檢測一次
 ${Green_font_prefix} * 2 * * * ${Font_color_suffix} 代表每天的第2點 檢測一次
 ${Green_font_prefix} 0 0 2 * * ${Font_color_suffix} 代表每2天的0點0分 檢測一次" && echo
	stty erase '^H' && read -p "(預設: */10 * * * *):" Crontab_time
	[[ -z "${Crontab_time}" ]] && Crontab_time="*/10 * * * *"
}
GO(){
	echo -e "========== 開始記錄測試訊息 [$(date '+%Y-%m-%d %H:%M:%S')]==========\n" >> ${log_file}
}
exit_GG(){
	echo -e "========== 記錄測試訊息結束 [$(date '+%Y-%m-%d %H:%M:%S')]==========\n\n" >> ${log_file}
	if [[ ${analysis_type} != "add" ]]; then
		Config_JSON="{\n\"servers\": [\n${Config_JSON}],\n\"updated\": \"$(date +%s)\"\n}"
		echo -e "${Config_JSON}" > ${JSON_file}
	fi
	exit 0
}
Continue_if(){
	Config_Status="false"
	[[ -z ${ip} ]] && ip="---.---.---.---"
	if [[ ${Like_num} == ${integer} ]]; then
		Config_JSON="${Config_JSON}{ \"ip\": \"${ip}\", \"name\": \"${Config_Name}\", \"type\": \"${Config_Type}\", \"type_1\": \"${Config_Type_1}\", \"location\": \"${Config_Location}\", \"status\": ${Config_Status}, \"time\": \"$(date '+%Y-%m-%d %H:%M:%S')\"  }\n"
	else
		Config_JSON="${Config_JSON}{ \"ip\": \"${ip}\", \"name\": \"${Config_Name}\", \"type\": \"${Config_Type}\", \"type_1\": \"${Config_Type_1}\", \"location\": \"${Config_Location}\", \"status\": ${Config_Status}, \"time\": \"$(date '+%Y-%m-%d %H:%M:%S')\"  },\n"
	fi
	continue
}
Get_Like(){
	[[ ! -e ${config_file} ]] && echo -e "${Error} 設定檔案不存在！(${config_file})" | tee -a ${log_file} && exit 0
	Like=$(cat "${config_file}")
	[[ -z ${Like} ]] && echo -e "${Error} 獲取SS/SSR帳號訊息失敗或設定檔案為空 !" | tee -a ${log_file} && exit 0
	Like_num=$(echo -e "${Like}"|wc -l)
}
Analysis_Config(){
	Config=$(echo -e "${Like}"|sed -n "$1"p)
	Config_info_base64=$(echo -e "${Config}"|awk -F '###' '{print $1}')
	Config_Name=$(echo -e "${Config}"|awk -F '###' '{print $2}')
	Config_Location=$(echo -e "${Config}"|awk -F '###' '{print $3}')
	Config_Disabled=$(echo -e "${Config}"|awk -F '###' '{print $4}')
	if [[ ${Config_Disabled} == "true" ]]; then
		echo -e "${Info} 帳號已禁用，跳過檢測 [${Config_info_base64}] !" | tee -a ${log_file}
		echo "---------------------------------------------------------"
		continue
	else
		Config_info_base64_determine=$(echo -e ${Config_info_base64}|cut -c 1-6)
		if [[ "${Config_info_base64_determine}" == "ssr://" ]]; then
			Config_Type="ShadowsocksR"
			Config_Type_1="SSR"
			Config_info=$(echo -e "${Config_info_base64}"|cut -c 7-2000|base64 -d)
			if [[ -z ${Config_info} ]]; then
				echo -e "${Error} Base64解密失敗 [${Config_info_base64}] !" | tee -a ${log_file}
				if [[ ${analysis_type} == "add" ]]; then
					exit_GG
				else
					Continue_if
				fi
			fi
			ssr_config
		else
			Config_Type="Shadowsocks"
			Config_Type_1="SS"
			Config_info=$(echo -e "${Config_info_base64}"|cut -c 6-2000|base64 -d)
			if [[ -z ${Config_info} ]]; then
				echo -e "${Error} Base64解密失敗 [${Config_info_base64}] !" | tee -a ${log_file}
				if [[ ${analysis_type} == "add" ]]; then
					exit_GG
				else
					Continue_if
				fi
			fi
			ss_config
		fi
	fi
}
ss_config(){
	zuo=$(echo -e "${Config_info}"|awk -F "@" '{print $1}')
	you=$(echo -e "${Config_info}"|awk -F "@" '{print $2}')
	port=$(echo -e "${you}"|awk -F ":" '{print $NF}')
	ip=$(echo -e "${you}"|awk -F ":${port}" '{print $1}')
	if [[ $(echo -e "${ip}"|wc -L) -lt 7 ]]; then
		echo -e "${Error} 錯誤，IP格式錯誤或為 ipv6地址[ ${ip} ]" | tee -a ${log_file}
		if [[ ${analysis_type} == "add" ]]; then
			exit_GG
		else
			Continue_if
		fi
	fi
	method=$(echo -e "${zuo}"|awk -F ":" '{print $1}')
	passwd=$(echo -e "${zuo}"|awk -F ":" '{print $2}')
	protocol="origin"
	obfs="plain"
	echo -e "${ip} ${port} ${method} ${passwd} ${protocol} ${obfs}"
	if [[ -z ${ip} ]] || [[ -z ${port} ]] || [[ -z ${method} ]] || [[ -z ${passwd} ]] || [[ -z ${protocol} ]] || [[ -z ${obfs} ]]; then
		echo -e "${Error} 錯誤，有部分 帳號參數為空！[ ${ip} ,${port} ,${method} ,${passwd} ,${protocol} ,${obfs} ]" | tee -a ${log_file}
		if [[ ${analysis_type} == "add" ]]; then
			exit_GG
		else
			Continue_if
		fi
	fi
}
ssr_config(){
	zuo=$(echo -e "${Config_info}"|awk -F "/?" '{print $1}')
	passwd_base64=$(echo -e "${zuo}"|awk -F ":" '{print $NF}')
	zuo=$(echo -e "${Config_info}"|awk -F ":${passwd_base64}" '{print $1}')
	obfs=$(echo -e "${zuo}"|awk -F ":" '{print $NF}')
	zuo=$(echo -e "${Config_info}"|awk -F ":${obfs}" '{print $1}')
	method=$(echo -e "${zuo}"|awk -F ":" '{print $NF}')
	zuo=$(echo -e "${Config_info}"|awk -F ":${method}" '{print $1}')
	protocol=$(echo -e "${zuo}"|awk -F ":" '{print $NF}')
	zuo=$(echo -e "${Config_info}"|awk -F ":${protocol}" '{print $1}')
	port=$(echo -e "${zuo}"|awk -F ":" '{print $NF}')
	ip=$(echo -e "${Config_info}"|awk -F ":${port}" '{print $1}')
	if [[ $(echo -e "${ip}"|wc -L) -lt 7 ]]; then
		echo -e "${Error} 錯誤，IP格式錯誤[ ${ip} ]" | tee -a ${log_file}
		if [[ ${analysis_type} == "add" ]]; then
			exit_GG
		else
			Continue_if
		fi
	fi
	passwd=$(echo -e "${passwd_base64}"|base64 -d)
	echo -e "${ip} ${port} ${method} ${passwd} ${protocol} ${obfs}"
	if [[ -z ${ip} ]] || [[ -z ${port} ]] || [[ -z ${method} ]] || [[ -z ${passwd} ]] || [[ -z ${protocol} ]] || [[ -z ${obfs} ]]; then
		echo -e "${Error} 錯誤，有部分 帳號參數為空！[ ${ip} ,${port} ,${method} ,${passwd} ,${protocol} ,${obfs} ]" | tee -a ${log_file}
		if [[ ${analysis_type} == "add" ]]; then
			exit_GG
		else
			Continue_if
		fi
	fi
}
Start_Client(){
	nohup python "${SSR_folder}/local.py" -b "127.0.0.1" -l "${local_port}" -s "${ip}" -p "${port}" -k "${passwd}" -m "${method}" -O "${protocol}" -o "${obfs}" > /dev/null 2>&1 &
	sleep 2s
	PID=$(ps -ef |grep -v grep | grep "local.py" | grep "${local_port}" |awk '{print $2}')
	if [[ -z ${PID} ]]; then
		echo -e "${Error} ShadowsocksR使用者端 啟動失敗，請檢查 !" | tee -a ${log_file}
		if [[ ${analysis_type} == "add" ]]; then
			exit_GG
		else
			Continue_if
		fi
	fi
}
Socks5_test(){
	Test_results=$(curl --socks5 127.0.0.1:${local_port} -k -m ${Timeout} -s "${Test_URL}")
	if [[ -z ${Test_results} ]]; then
		echo -e "${Error} [${ip}] 檢測失敗，帳號不可用，重新嘗試一次..." | tee -a ${log_file}
		sleep 2s
		Test_results=$(curl --socks5 127.0.0.1:${local_port} -k -m ${Timeout} -s "${Test_URL}")
		if [[ -z ${Test_results} ]]; then
			echo -e "${Error} [${ip}] 檢測失敗，帳號不可用(已重新嘗試) !" | tee -a ${log_file}
			Config_Status="false"
		else
			echo -e "${Info} [${ip}] 檢測成功，帳號可用 !" | tee -a ${log_file}
			Config_Status="true"
		fi
	else
		echo -e "${Info} [${ip}] 檢測成功，帳號可用 !" | tee -a ${log_file}
		Config_Status="true"
	fi
	kill -9 ${PID}
	PID=$(ps -ef |grep -v grep | grep "local.py" | grep "${local_port}" |awk '{print $2}')
	if [[ ! -z ${PID} ]]; then
		echo -e "${Error} ShadowsocksR使用者端 停止失敗，請檢查 !" | tee -a ${log_file}
		if [[ ${analysis_type} == "add" ]]; then
			exit_GG
		else
			Continue_if
		fi
	fi
	echo "---------------------------------------------------------"
	if [[ ${analysis_type} != "add" ]]; then
		if [[ ${Like_num} == ${integer} ]]; then
			Config_JSON="${Config_JSON}{ \"ip\": \"${ip}\", \"name\": \"${Config_Name}\", \"type\": \"${Config_Type}\", \"type_1\": \"${Config_Type_1}\", \"location\": \"${Config_Location}\", \"status\": ${Config_Status}, \"time\": \"$(date '+%Y-%m-%d %H:%M:%S')\"  }\n"
		else
			Config_JSON="${Config_JSON}{ \"ip\": \"${ip}\", \"name\": \"${Config_Name}\", \"type\": \"${Config_Type}\", \"type_1\": \"${Config_Type_1}\", \"location\": \"${Config_Location}\", \"status\": ${Config_Status}, \"time\": \"$(date '+%Y-%m-%d %H:%M:%S')\"  },\n"
		fi
	fi
}
rand(){
	min=1000
	max=$((2000-$min+1))
	num=$(date +%s%N)
	echo $(($num%$max+$min))
}
Test(){
	GO
	Get_Like
	cd ${SSR_folder}
	local_port=$(rand)
	for((integer = 1; integer <= "${Like_num}"; integer++))
	do
		Analysis_Config "${integer}"
		Start_Client
		Socks5_test
	done
	exit_GG
}
Test_add(){
	analysis_type="add"
	GO
	cd ${SSR_folder}
	local_port=$(rand)
	set_config_user
	[[ $? == 2 ]] && Analysis_Config "1"
	Start_Client
	Socks5_test
	exit_GG
}
Test_one(){
	List_SSRStatus
	cd ${SSR_folder}
	local_port=$(rand)
	while true
	do
	echo -e "請選擇你要單獨測試的帳號序號"
	stty erase '^H' && read -p "(預設取消):" Test_one_num
	[[ -z "${Test_one_num}" ]] && echo "已取消..." && exit 1
	expr ${Test_one_num} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${Test_one_num} -ge 1 ]] && [[ ${Test_one_num} -le ${Like_num} ]]; then
			analysis_type="add" && Analysis_Config "${Test_one_num}"
			Start_Client
			Socks5_test
			break
		else
			echo -e "${Error} 請輸入正確的數位！"
		fi
	else
		echo -e "${Error} 請輸入正確的數位！"
	fi
	done
}
View_log(){
	[[ ! -e ${log_file} ]] && echo -e "${Error} 找不到 日誌檔案！(${log_file})"
	cat "${log_file}"
}
Set_SSRStatus(){
	check_installed_server_status
	echo && echo -e " 你要做什麼？
	
 ${Green_font_prefix} 1.${Font_color_suffix} 添加 帳號設定
 ${Green_font_prefix} 2.${Font_color_suffix} 刪除 帳號設定
 ${Green_font_prefix} 3.${Font_color_suffix} 修改 帳號設定
————————
 ${Green_font_prefix} 4.${Font_color_suffix} 啟用/禁用 帳號設定
 注意：添加/修改/刪除 帳號設定後，不會立即更新，需要自動(定時)/手動檢測一次所有帳號，網頁才會更新 !" && echo
	stty erase '^H' && read -p "(預設: 取消):" server_num
	[[ -z "${server_num}" ]] && echo "已取消..." && exit 1
	if [[ ${server_num} == "1" ]]; then
		Add_SSRStatus
	elif [[ ${server_num} == "2" ]]; then
		Del_SSRStatus
	elif [[ ${server_num} == "3" ]]; then
		Modify_SSRStatus
	elif [[ ${server_num} == "4" ]]; then
		Modify_SSRStatus_disabled
	else
		echo -e "${Error} 請輸入正確的數位[1-4]" && exit 1
	fi
}
List_SSRStatus(){
	Get_Like
	echo -e "目前有 ${Like_num} 個帳號設定\n$(echo -e "${Like}"|grep -n "#")"
}
Add_SSRStatus(){
	set_config_user
	if [[ $? == 1 ]]; then
		if [[ ${protocol} == "origin" ]] && [[ ${obfs} == "plain" ]]; then
			Like_base64=$(echo -n "${method}:${passwd}@${ip}:${port}"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g')
			Like="ss://"${Like_base64}
		else
			passwd_base64=$(echo -n "${passwd}"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g')
			Like_base64=$(echo -n "${ip}:${port}:${protocol}:${method}:${obfs}:${passwd_base64}"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g')
			Like="ssr://"${Like_base64}
		fi
	fi
	set_config_name
	set_config_location
	Like="${Like}###${Config_Name}###${Config_Location}###false"
	echo -e "${Like}" >> ${config_file}
	if [[ $? == 0 ]]; then
		echo -e "${Info} 添加成功 ! [${Like}]"
	else
		echo -e "${Error} 添加失敗 ! [${Like}]"
	fi
}
Del_SSRStatus(){
	List_SSRStatus
	[[ ${Like_num} == 1 ]] && echo -e "${Error} 目前僅剩一個帳號設定，無法刪除 !" && exit 0
	while true
	do
	echo -e "請選擇你要刪除的帳號序號"
	stty erase '^H' && read -p "(預設取消):" Del_num
	[[ -z "${Del_num}" ]] && echo "已取消..." && exit 1
	expr ${Del_num} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${Del_num} -ge 1 ]] && [[ ${Del_num} -le ${Like_num} ]]; then
			sed -i "${Del_num}d" ${config_file}
			if [[ $? == 0 ]]; then
				echo -e "${Info} 刪除成功 ! [${Del_num}]"
			else
				echo -e "${Error} 刪除失敗 ! [${Del_num}]"
			fi
			break
		else
			echo -e "${Error} 請輸入正確的數位！"
		fi
	else
		echo -e "${Error} 請輸入正確的數位！"
	fi
	done
}
Modify_SSRStatus(){
	List_SSRStatus
	while true
	do
	echo -e "請選擇你要修改的帳號序號"
	stty erase '^H' && read -p "(預設取消):" Modify_num
	[[ -z "${Modify_num}" ]] && echo "已取消..." && exit 1
	expr ${Modify_num} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${Modify_num} -ge 1 ]] && [[ ${Modify_num} -le ${Like_num} ]]; then
			set_config_user
			if [[ $? == 1 ]]; then
				if [[ ${protocol} == "origin" ]] && [[ ${obfs} == "plain" ]]; then
					Like_base64=$(echo -n "${method}:${passwd}@${ip}:${port}"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g')
					Like="ss://"${Like_base64}
				else
					passwd_base64=$(echo -n "${passwd}"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g')
					Like_base64=$(echo -n "${ip}:${port}:${protocol}:${method}:${obfs}:${passwd_base64}"|base64|sed ':a;N;s/\n/ /g;ta'|sed 's/ //g;s/=//g')
					Like="ssr://"${Like_base64}
				fi
			fi
			set_config_name
			set_config_location
			Like="${Like}###${Config_Name}###${Config_Location}###false"
			sed -i "${Modify_num}d" ${config_file}
			sed -i "${Modify_num}i\\${Like}" ${config_file}
			if [[ $? == 0 ]]; then
				echo -e "${Info} 修改成功 ! [${Like}]"
			else
				echo -e "${Error} 修改失敗 ! [${Like}]"
			fi
			break
		else
			echo -e "${Error} 請輸入正確的數位！"
		fi
	else
		echo -e "${Error} 請輸入正確的數位！"
	fi
	done
}
Modify_SSRStatus_disabled(){
	List_SSRStatus
	while true
	do
	echo -e "請選擇你要啟用/禁用的帳號序號"
	stty erase '^H' && read -p "(預設取消):" Modify_num
	[[ -z "${Modify_num}" ]] && echo "已取消..." && exit 1
	expr ${Modify_num} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${Modify_num} -ge 1 ]] && [[ ${Modify_num} -le ${Like_num} ]]; then
			Config_old=$(echo -e "${Like}"|sed -n "${Modify_num}"p)
			echo -e "${Config_old}"
			Config_old_Disabled=$(echo -e "${Config_old}"|awk -F '###' '{print $4}')
			Config_old=$(echo -e "${Config_old}"|awk -F "###${Config_old_Disabled}" '{print $1}')
			echo -e "${Config_old_Disabled}\n${Config_old}"
			if [[ ${Config_old_Disabled} == "true" ]]; then
				Config_Disabled="false"
				Like="${Config_old}###${Config_Disabled}"
			else
				Config_Disabled="true"
				Like="${Config_old}###${Config_Disabled}"
			fi
			echo -e "${Config_Disabled}\n${Like}"
			sed -i "${Modify_num}d" ${config_file}
			sed -i "${Modify_num}i\\${Like}" ${config_file}
			if [[ $? == 0 ]]; then
				echo -e "${Info} 修改成功 ! [帳號狀態為: ${Config_Disabled}]"
			else
				echo -e "${Error} 修改失敗 ! [帳號狀態為: ${Config_Disabled}]"
			fi
			break
		else
			echo -e "${Error} 請輸入正確的數位！"
		fi
	else
		echo -e "${Error} 請輸入正確的數位！"
	fi
	done
}
Installation_dependency(){
	if [[ ${release} == "centos" ]]; then
		yum update
		yum install -y unzip vim curl crond
		[[ -z $(ls /usr/sbin/crond) ]] && echo -e "${Error} 依賴 crond 安裝失敗..." && exit 0
	else
		apt-get update
		apt-get install -y unzip vim curl cron
		[[ -z $(ls /usr/sbin/cron) ]] && echo -e "${Error} 依賴 cron 安裝失敗..." && exit 0
	fi
	[[ -z $(unzip --help) ]] && echo -e "${Error} 依賴 unzip 安裝失敗..." && exit 0
	[[ -z $(curl --help) ]] && echo -e "${Error} 依賴 curl 安裝失敗..." && exit 0
	cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}
Install_caddy(){
	echo -e "是否由腳本自動設定HTTP服務(線上監控網站)[Y/n]"
	stty erase '^H' && read -p "(預設: Y 自動部署):" caddy_yn
	[[ -z "$caddy_yn" ]] && caddy_yn="y"
	if [[ "${caddy_yn}" == [Yy] ]]; then
		Set_server
		Set_server_port
		if [[ ! -e "/usr/local/caddy/caddy" ]]; then
			wget -N --no-check-certificate https://raw.githubusercontent.com/david082321/doubi/master/caddy_install.sh
			chmod +x caddy_install.sh
			bash caddy_install.sh install
			[[ ! -e "/usr/local/caddy/caddy" ]] && echo -e "${Error} Caddy安裝失敗，請手動部署，Web網頁檔案位置：${Web_file}" && exit 0
		else
			echo -e "${Info} 發現Caddy已安裝，開始設定..."
		fi
		if [[ ! -s "/usr/local/caddy/Caddyfile" ]]; then
			cat > "/usr/local/caddy/Caddyfile"<<-EOF
http://${server_s}:${server_port_s} {
 root ${Web_file}
 timeouts none
 gzip
}
EOF
			/etc/init.d/caddy restart
		else
			echo -e "${Info} 發現 Caddy 設定檔案非空，開始追加 ServerStatus 網站設定內容到檔案最後..."
			cat >> "/usr/local/caddy/Caddyfile"<<-EOF
http://${server_s}:${server_port_s} {
 root ${Web_file}
 timeouts none
 gzip
}
EOF
			/etc/init.d/caddy restart
		fi
	else
		echo -e "${Info} 跳過 HTTP服務部署，請手動部署，Web網頁檔案位置：${Web_file} !"
	fi
}
Download_SSRStatus(){
	cd "/usr/local"
	wget -N --no-check-certificate "https://github.com/david082321/SSRStatus/archive/master.zip"
	[[ ! -e "master.zip" ]] && echo -e "${Error} SSRStatus 網頁檔案下載失敗 !" && exit 1
	unzip master.zip && rm -rf master.zip
	[[ ! -e "SSRStatus-master" ]] && echo -e "${Error} SSRStatus 網頁檔案解壓失敗 !" && exit 1
	mv SSRStatus-master SSRStatus
	[[ ! -e "${Web_file}" ]] && echo -e "${Error} SSRStatus 網頁檔案資料夾重新命名失敗 !" && rm -rf SSRStatus-master && exit 1
}
Install_Web(){
	[[ -e "${Web_file}" ]] && echo -e "${Error} 檢測到 SSRStatus 網頁檔案已安裝 !" && exit 1
	check_sys
	echo -e "${Info} 開始安裝/設定 依賴..."
	Installation_dependency
	echo -e "${Info} 開始部署HTTP服務(Caddy)..."
	Install_caddy
	echo -e "${Info} 開始下載/安裝..."
	Download_SSRStatus
	echo -e "${Info} 開始設定定時任務..."
	Set_crontab
	echo -e "${Info} 所有步驟 安裝完畢... 請打開本腳本並修改開頭的 SSR_folder 變數引號內的ShadowsocksR子目錄絕對路徑，方可使用。"
}
Uninstall_Web(){
	check_installed_server_status
	echo "確定要移除 SSRStatus 網頁檔案(自動部署的Caddy並不會刪除) ? [y/N]"
	echo
	stty erase '^H' && read -p "(預設: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		/etc/init.d/caddy stop
		Del_Crontab
		rm -rf "${Web_file}"
		echo && echo "SSRStatus 網頁檔案移除完成 !" && echo
	else
		echo && echo "移除已取消..." && echo
	fi
}
Add_Crontab(){
	crontab -l > "$file/crontab.bak"
	sed -i "/ssrstatus.sh/d" "$file/crontab.bak"
	echo -e "\n${Crontab_time} /bin/bash $file/ssrstatus.sh t" >> "$file/crontab.bak"
	crontab "$file/crontab.bak"
	rm -r "$file/crontab.bak"
	cron_config=$(crontab -l | grep "ssrstatus.sh")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} 添加 Crontab 定時任務失敗 !" && exit 1
	else
		echo -e "${Info} 添加 Crontab 定時任務成功 !"
	fi
}
Del_Crontab(){
	crontab -l > "$file/crontab.bak"
	sed -i "/ssrstatus.sh/d" "$file/crontab.bak"
	crontab "$file/crontab.bak"
	rm -r "$file/crontab.bak"
	cron_config=$(crontab -l | grep "ssrstatus.sh")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} 刪除 Crontab 定時任務失敗 !" && exit 1
	else
		echo -e "${Info} 刪除 Crontab 定時任務成功 !"
	fi
}
Update_Shell(){
	echo -e "目前版本為 [ ${sh_ver} ]，開始檢測最新版本..."
	sh_new_ver=$(wget --no-check-certificate -qO- "https://softs.loan/Bash/ssrstatus.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="softs"
	[[ -z ${sh_new_ver} ]] && sh_new_ver=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/david082321/doubi/master/ssrstatus.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 檢測最新版本失敗 !" && exit 0
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "發現新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
		stty erase '^H' && read -p "(預設: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			if [[ $sh_new_type == "softs" ]]; then
				wget -N --no-check-certificate https://softs.loan/Bash/ssrstatus.sh && chmod +x ssrstatus.sh
			else
				wget -N --no-check-certificate https://raw.githubusercontent.com/david082321/doubi/master/ssrstatus.sh && chmod +x ssrstatus.sh
			fi
			echo -e "腳本已更新為最新版本[ ${sh_new_ver} ] !"
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo -e "目前已是最新版本[ ${sh_new_ver} ] !"
	fi
}
menu(){
echo && echo -e "  SSRStatus 一鍵安裝管理腳本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/shell-jc5 --
  
 ${Green_font_prefix}0.${Font_color_suffix} 升級腳本
 ————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安裝 依賴及Web網頁
 ${Green_font_prefix}2.${Font_color_suffix} 移除 依賴及Web網頁
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 測試 所有帳號
 ${Green_font_prefix}4.${Font_color_suffix} 測試 單獨帳號
 ${Green_font_prefix}5.${Font_color_suffix} 測試 自訂帳號
————————————
 ${Green_font_prefix}6.${Font_color_suffix} 設定 設定訊息
 ${Green_font_prefix}7.${Font_color_suffix} 查看 設定訊息
 ${Green_font_prefix}8.${Font_color_suffix} 查看 執行日誌
 ${Green_font_prefix}9.${Font_color_suffix} 設定 定時間隔
————————————" && echo
if [[ -e ${Web_file} ]]; then
	echo -e " 目前狀態: Web網頁 ${Green_font_prefix}已安裝${Font_color_suffix}"
else
	echo -e " 目前狀態: Web網頁 ${Red_font_prefix}未安裝${Font_color_suffix}"
fi
echo
stty erase '^H' && read -p " 請輸入數字 [0-9]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_Web
	;;
	2)
	Uninstall_Web
	;;
	3)
	Test
	;;
	4)
	Test_one
	;;
	5)
	Test_add
	;;
	6)
	Set_SSRStatus
	;;
	7)
	List_SSRStatus
	;;
	8)
	View_log
	;;
	9)
	Set_crontab
	;;
	*)
	echo "請輸入正確數字 [0-9]"
	;;
esac
}
action=$1
if [[ ${1} == "t" ]]; then
	Test
elif [[ ${1} == "a" ]]; then
	Test_add
elif [[ ${1} == "o" ]]; then
	Test_one
elif [[ ${1} == "log" ]]; then
	View_log
else
	menu
fi
