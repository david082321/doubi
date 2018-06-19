#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: Debian/Ubuntu
#	Description: SSH modify port
#	Version: 1.0.0
#	Author: Toyo
#	Blog: https://doub.io/linux-jc11/
#=================================================

sh_ver="1.0.0"
CONF="/etc/ssh/sshd_config"
SSH_init_1="/etc/init.d/ssh"
SSH_init_2="/etc/init.d/sshd"
if [[ -e ${SSH_init_1} ]]; then
	SSH_init=${SSH_init_1}
elif [[ -e ${SSH_init_2} ]]; then
	SSH_init=${SSH_init_2}
else
	echo -e "${Error} 找不到 SSH 的服務腳本檔案！" && exit 1
fi
bak_text="（可透過備份SSH設定檔案復原：[ ${Green_font_prefix}rm -rf /etc/ssh/sshd_config && mv /etc/ssh/sshd_config.bak /etc/ssh/sshd_config && rm -rf /etc/ssh/sshd_config.bak && ${SSH_init} restart${Font_color_suffix} ]）"
over_text="${Tip} 當伺服器存在外部防火牆時（如 阿里雲、騰訊雲、微軟雲、Google雲、亞馬遜雲等），需要外部防火牆開放 新SSH埠TCP協議方可連接！"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[訊息]${Font_color_suffix}" && Error="${Red_font_prefix}[錯誤]${Font_color_suffix}" && Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
filepath=$(cd "$(dirname "$0")"; pwd)
file=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')

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
	[[ ! -e ${CONF} ]] && echo -e "${Error} SSH設定檔案不存在[ ${CONF} ]，請檢查 !" && exit 1
}
check_pid(){
	PID=$(ps -ef| grep '/usr/sbin/sshd'| grep -v grep| awk '{print $2}')
}
Read_config(){
	port_all=$(cat ${CONF}|grep -v '#'|grep "Port "|awk '{print $2}')
	if [[ -z ${port_all} ]]; then
		port=22
	else
		port=${port_all}
	fi
}
Set_port(){
	while true
		do
		echo -e "\n舊SSH埠：${Green_font_prefix}[${port}]${Font_color_suffix}"
		echo -e "請輸入新的SSH埠 [1-65535]"
		stty erase '^H' && read -p "(輸入為空則取消):" new_port
		[[ -z "${new_port}" ]] && echo "取消..." && exit 1
		expr ${new_port} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${new_port} -ge 1 ]] && [[ ${new_port} -le 65535 ]]; then
				if [[ ${new_port} == ${port} ]]; then
					echo -e "輸入錯誤, 新埠與舊埠一致。"
				else
					echo && echo "============================="
					echo -e "	新埠 : ${Red_background_prefix} ${new_port} ${Font_color_suffix}"
					echo "=============================" && echo
					break
				fi
			else
				echo -e "輸入錯誤, 請輸入正確的埠。"
			fi
		else
			echo -e "輸入錯誤, 請輸入正確的埠。"
		fi
	done
}
choose_the_way(){
	echo -e "請選擇SSH埠修改方式：
 1. 直接修改（直接修改舊埠為新埠，並且防火牆禁止舊埠 開放新埠）
 2. 保守修改（不刪除舊埠，先添加新埠，然後手動斷開SSH連結並使用新埠嘗試連結，如果連結正常，那麼再次執行腳本刪除舊埠設定）\n
 一般來說修改SSH埠不會出現什麼問題，但保守起見，我做了兩個修改方式。
 如果不懂請選 ${Green_font_prefix}[2. 保守修改]${Font_color_suffix}，避免因為未知問題而導致修改後無法透過 新埠和舊埠 連結伺服器！\n
 ${over_text}\n"
	stty erase '^H' && read -p "(預設: 2. 保守修改):" choose_the_way_num
	[[ -z "${choose_the_way_num}" ]] && choose_the_way_num="2"
	if [[ ${choose_the_way_num} == "1" ]]; then
		cp -f "${CONF}" "/etc/ssh/sshd_config.bak"
		Direct_modification
	elif [[ ${choose_the_way_num} == "2" ]]; then
		cp -f "${CONF}" "/etc/ssh/sshd_config.bak"
		Conservative_modifications
	else
		echo -e "${Error} 請輸入正確的數位 [1-2]" && exit 1
	fi
}
Direct_modification(){
	echo -e "${Info} 刪除舊埠設定..."
	sed -i "/Port ${port}/d" "${CONF}"
	echo -e "${Info} 添加新埠設定..."
	echo -e "\nPort ${new_port}" >> "${CONF}"
	${SSH_init} restart
	sleep 2s
	check_pid
	if [[ -z ${PID} ]]; then
			echo -e "${Error} SSH 啟動失敗 !${bak_text}" && exit 1
		else
			port_status=$(netstat -lntp|grep ssh|awk '{print $4}'|grep -w "${new_port}")
			if [[ -z ${port_status} ]]; then
				echo -e "${Error} SSH 埠修改失敗 !${bak_text}" && exit 1
			else
				Del_iptables_ACCEPT
				Del_iptables_DROP
				Add_iptables_ACCEPT
				Add_iptables_DROP
				Set_iptables
				rm -rf /etc/ssh/sshd_config.bak
				echo -e "${Info} SSH 埠修改成功！新埠：[${Green_font_prefix}${new_port}${Font_color_suffix}]"
				echo -e "${over_text}"
			fi
		fi
}
Conservative_modifications(){
	if [[ $1 != "End" ]]; then
		echo -e "${Info} 添加新埠設定..."
		echo -e "\nPort ${new_port}" >> "${CONF}"
		${SSH_init} restart
		sleep 2s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} SSH 啟動失敗 !${bak_text}" && exit 1
		else
			port_status=$(netstat -lntp|grep ssh|awk '{print $4}'|grep -w "${new_port}")
			if [[ -z ${port_status} ]]; then
				echo -e "${Error} SSH 埠添加失敗 !${bak_text}" && exit 1
			else
				Add_iptables_ACCEPT
				Set_iptables
				echo "${new_port}|${port}" > "${file}/ssh_port.conf"
				echo -e "${Info} SSH 埠添加成功 ! 
請手動斷開 SSH連結並使用新埠 ${Green_font_prefix}[${new_port}]${Font_color_suffix} 嘗試連結，如無法連結 請透過舊埠 ${Green_font_prefix}[${port}]${Font_color_suffix} 連結，如連結正常 請連結後再次執行腳本${Green_font_prefix} [bash ${file}/ssh_port.sh end]${Font_color_suffix} 以刪除舊埠設定！"
				echo -e "${over_text}"
			fi
		fi
	else
		[[ ! -e "${file}/ssh_port.conf" ]] && echo -e "${Error} ${file}/ssh_port.conf 檔案缺失 !" && exit 1
		new_port=$(cat "${file}/ssh_port.conf"|awk -F '|' '{print $1}')
		port=$(cat "${file}/ssh_port.conf"|awk -F '|' '{print $2}')
		rm -rf "${file}/ssh_port.conf"
		echo -e "${Info} 刪除舊埠設定..."
		sed -i "/Port ${port}/d" "${CONF}"
		${SSH_init} restart
		sleep 2s
		check_pid
		if [[ -z ${PID} ]]; then
			echo -e "${Error} SSH 啟動失敗 !" && exit 1
		else
			Add_iptables_DROP
			Set_iptables
			rm -rf /etc/ssh/sshd_config.bak
			echo -e "${Info} 所有設定完成！新埠：[${Green_font_prefix}${new_port}${Font_color_suffix}]"
			echo -e "${over_text}"
		fi
	fi
}
modify_ssh(){
	Read_config
	Set_port
	choose_the_way
}
end_ssh(){
	Conservative_modifications "End"
}
Add_iptables_ACCEPT(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${new_port} -j ACCEPT
}
Del_iptables_ACCEPT(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j ACCEPT
}
Add_iptables_DROP(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${port} -j DROP
}
Del_iptables_DROP(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${new_port} -j DROP
}
Set_iptables(){
	iptables-save > /etc/iptables.up.rules
	echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
	chmod +x /etc/network/if-pre-up.d/iptables
}
check_sys
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && echo -e "${Error} 本腳本不支援目前系統 ${release} !" && exit 1
check_installed_status
action=$1
[[ -z $1 ]] && action=modify
case "$action" in
    modify|end)
    ${action}_ssh
    ;;
    *)
    echo "輸入錯誤 !"
    echo "用法: {modify|end}"
    ;;
esac
