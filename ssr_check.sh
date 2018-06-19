#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6+/Debian 7+/Ubuntu 14.04+
#	Description: ShadowsocksR Config Check
#	Version: 1.0.3
#	Author: Toyo
#=================================================

Timeout="10"
Test_URL="https://github.com"
SSR_folder="/root/shadowsocksr/shadowsocks"
log_file="$PWD/ssr_check.log"
config_file="$PWD/ssr_check.conf"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[訊息]${Font_color_suffix}" && Error="${Red_font_prefix}[錯誤]${Font_color_suffix}" && Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

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
 ${Tip} 如果使用 auth_chain_a 協議，請加密方式選擇 none，混淆隨意(建議 plain)
 
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
	echo -e "請選擇要設置的ShadowsocksR帳號 協議插件
 ${Green_font_prefix}1.${Font_color_suffix} origin
 ${Green_font_prefix}2.${Font_color_suffix} auth_sha1_v4
 ${Green_font_prefix}3.${Font_color_suffix} auth_aes128_md5
 ${Green_font_prefix}4.${Font_color_suffix} auth_aes128_sha1
 ${Green_font_prefix}5.${Font_color_suffix} auth_chain_a
 ${Tip} 如果使用 auth_chain_a 協議，請加密方式選擇 none，混淆隨意(建議 plain)" && echo
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
	echo -e "請選擇要設置的ShadowsocksR帳號 混淆插件
 ${Green_font_prefix}1.${Font_color_suffix} plain
 ${Green_font_prefix}2.${Font_color_suffix} http_simple
 ${Green_font_prefix}3.${Font_color_suffix} http_post
 ${Green_font_prefix}4.${Font_color_suffix} random_head
 ${Green_font_prefix}5.${Font_color_suffix} tls1.2_ticket_auth
 ${Tip} 如果使用 ShadowsocksR 加速遊戲，請選擇 混淆相容原版或 plain 混淆，然後使用者端選擇 plain，否則會增加延遲 !" && echo
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
GO(){
	echo -e "========== 開始記錄測試訊息 [$(date '+%Y-%m-%d %H:%M:%S')]==========\n" >> ${log_file}
}
exit_GG(){
	echo -e "========== 記錄測試訊息結束 [$(date '+%Y-%m-%d %H:%M:%S')]==========\n\n" >> ${log_file}
	exit 0
}
Get_Like(){
	[[ ! -e ${config_file} ]] && echo -e "${Error} 設定檔案不存在！(${config_file})" | tee -a ${log_file} && exit_GG
	Like=$(cat "${config_file}")
	[[ -z ${Like} ]] && echo -e "${Error} 獲取SS/SSR帳號訊息失敗或設定檔案為空 !" | tee -a ${log_file} && exit_GG
	Like_num=$(echo -e "${Like}"|wc -l)
}
Analysis_Config(){
	Config_info_base64=$(echo -e "${Like}"|sed -n "$1"p)
	Config_info_base64_determine=$(echo -e ${Config_info_base64}|cut -c 1-6)
	if [[ "${Config_info_base64_determine}" == "ssr://" ]]; then
		Config_info=$(echo -e "${Config_info_base64}"|cut -c 7-2000|base64 -d)
		if [[ -z ${Config_info} ]]; then
			echo -e "${Error} Base64解密失敗 [${Config_info_base64}] !" | tee -a ${log_file}
			if [[ ${analysis_type} == "add" ]]; then
				exit_GG
			else
				continue
			fi
		fi
		ssr_config
	else
		Config_info=$(echo -e "${Config_info_base64}"|cut -c 6-2000|base64 -d)
		if [[ -z ${Config_info} ]]; then
			echo -e "${Error} Base64解密失敗 [${Config_info_base64}] !" | tee -a ${log_file}
			if [[ ${analysis_type} == "add" ]]; then
				exit_GG
			else
				continue
			fi
		fi
		ss_config
	fi
}
ss_config(){
	zuo=$(echo -e "${Config_info}"|awk -F "@" '{print $1}')
	you=$(echo -e "${Config_info}"|awk -F "@" '{print $2}')
	port=$(echo -e "${you}"|awk -F ":" '{print $NF}')
	ip=$(echo -e "${you}"|awk -F ":${port}" '{print $1}')
	if [[ $(echo -e "${ip}"|wc -L) -le 8 ]]; then
		echo -e "${Error} 錯誤，IP格式錯誤或為 ipv6地址[ ${ip} ]" | tee -a ${log_file}
		if [[ ${analysis_type} == "add" ]]; then
			exit_GG
		else
			continue
		fi
	fi
	method=$(echo -e "${zuo}"|awk -F ":" '{print $1}')
	passwd=$(echo -e "${zuo}"|awk -F ":" '{print $2}')
	protocol="origin"
	obfs="plain"
	if [[ -z ${ip} ]] || [[ -z ${port} ]] || [[ -z ${method} ]] || [[ -z ${passwd} ]] || [[ -z ${protocol} ]] || [[ -z ${obfs} ]]; then
		echo -e "${Error} 錯誤，有部分 帳號參數為空！[ ${ip} ,${port} ,${method} ,${passwd} ,${protocol} ,${obfs} ]" | tee -a ${log_file}
		if [[ ${analysis_type} == "add" ]]; then
			exit_GG
		else
			continue
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
	if [[ $(echo -e "${ip}"|wc -L) -le 8 ]]; then
		echo -e "${Error} 錯誤，IP格式錯誤[ ${ip} ]" | tee -a ${log_file}
		if [[ ${analysis_type} == "add" ]]; then
			exit_GG
		else
			Continue_if
		fi
	fi
	passwd=$(echo -e "${passwd_base64}"|base64 -d)
	if [[ -z ${ip} ]] || [[ -z ${port} ]] || [[ -z ${method} ]] || [[ -z ${passwd} ]] || [[ -z ${protocol} ]] || [[ -z ${obfs} ]]; then
		echo -e "${Error} 錯誤，有部分 帳號參數為空！[ ${ip} ,${port} ,${method} ,${passwd} ,${protocol} ,${obfs} ]" | tee -a ${log_file}
		if [[ ${analysis_type} == "add" ]]; then
			exit_GG
		else
			continue
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
			continue
		fi
	fi
}
Socks5_test(){
	Test_results=$(curl --socks5 127.0.0.1:${local_port} -k -m ${Timeout} -s "${Test_URL}")
	if [[ -z ${Test_results} ]]; then
		echo -e "${Error} [${ip}] 檢測失敗，帳號不可用 !" | tee -a ${log_file}
		Config_Status="false"
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
			continue
		fi
	fi
	echo "---------------------------------------------------------"
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
	GO
	cd ${SSR_folder}
	local_port=$(rand)
	set_config_user
	[[ $? == 2 ]] && analysis_type="add" && Analysis_Config "1"
	Start_Client
	Socks5_test
	exit_GG
}
View_log(){
	[[ ! -e ${log_file} ]] && echo -e "${Error} 找不到 日誌檔案！(${log_file})"
	cat "${log_file}"
}
action=$1
if [[ ${1} == "t" ]]; then
	Test
elif [[ ${1} == "a" ]]; then
	Test_add
elif [[ ${1} == "log" ]]; then
	View_log
fi
