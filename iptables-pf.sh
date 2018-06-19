#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: iptables Port forwarding
#	Version: 1.1.1
#	Author: Toyo
#	Blog: https://doub.io/wlzy-20/
#=================================================
sh_ver="1.1.1"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[訊息]${Font_color_suffix}"
Error="${Red_font_prefix}[錯誤]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_iptables(){
	iptables_exist=$(iptables -V)
	[[ ${iptables_exist} = "" ]] && echo -e "${Error} 沒有安裝iptables，請檢查 !" && exit 1
}
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
install_iptables(){
	iptables_exist=$(iptables -V)
	if [[ ${iptables_exist} != "" ]]; then
		echo -e "${Info} 已經安裝iptables，繼續..."
	else
		echo -e "${Info} 檢測到未安裝 iptables，開始安裝..."
		if [[ ${release}  == "centos" ]]; then
			yum update
			yum install -y vim iptables
		else
			apt-get update
			apt-get install -y vim iptables
		fi
		iptables_exist=$(iptables -V)
		if [[ ${iptables_exist} = "" ]]; then
			echo -e "${Error} 安裝iptables失敗，請檢查 !" && exit 1
		else
			echo -e "${Info} iptables 安裝完成 !"
		fi
	fi
	echo -e "${Info} 開始設定 iptables !"
	Set_iptables
	echo -e "${Info} iptables 設定完畢 !"
}
Set_forwarding_port(){
	stty erase '^H' && read -p "請輸入 iptables 欲轉發至的 遠程埠 [1-65535] (支援埠段 如 2333-6666, 被轉發伺服器):" forwarding_port
	[[ -z "${forwarding_port}" ]] && echo "取消..." && exit 1
	echo && echo -e "	欲轉發埠 : ${Red_font_prefix}${forwarding_port}${Font_color_suffix}" && echo
}
Set_forwarding_ip(){
		stty erase '^H' && read -p "請輸入 iptables 欲轉發至的 遠程IP(被轉發伺服器):" forwarding_ip
		[[ -z "${forwarding_ip}" ]] && echo "取消..." && exit 1
		echo && echo -e "	欲轉發伺服器IP : ${Red_font_prefix}${forwarding_ip}${Font_color_suffix}" && echo
}
Set_local_port(){
	echo -e "請輸入 iptables 本機監聽埠 [1-65535] (支援埠段 如 2333-6666)"
	stty erase '^H' && read -p "(預設埠: ${forwarding_port}):" local_port
	[[ -z "${local_port}" ]] && local_port="${forwarding_port}"
	echo && echo -e "	本機監聽埠 : ${Red_font_prefix}${local_port}${Font_color_suffix}" && echo
}
Set_local_ip(){
	stty erase '^H' && read -p "請輸入 本伺服器的 網卡IP(注意是網卡綁定的IP，而不僅僅是公網IP，回車自動檢測外網IP):" local_ip
	if [[ -z "${local_ip}" ]]; then
		local_ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
		if [[ -z "${local_ip}" ]]; then
			echo "${Error} 無法檢測到本伺服器的公網IP，請手動輸入"
			stty erase '^H' && read -p "請輸入 本伺服器的 網卡IP(注意是網卡綁定的IP，而不僅僅是公網IP):" local_ip
			[[ -z "${local_ip}" ]] && echo "取消..." && exit 1
		fi
	fi
	echo && echo -e "	本伺服器IP : ${Red_font_prefix}${local_ip}${Font_color_suffix}" && echo
}
Set_forwarding_type(){
	echo -e "請輸入數字 來選擇 iptables 轉發類型:
 1. TCP
 2. UDP
 3. TCP+UDP\n"
	stty erase '^H' && read -p "(預設: TCP+UDP):" forwarding_type_num
	[[ -z "${forwarding_type_num}" ]] && forwarding_type_num="3"
	if [[ ${forwarding_type_num} == "1" ]]; then
		forwarding_type="TCP"
	elif [[ ${forwarding_type_num} == "2" ]]; then
		forwarding_type="UDP"
	elif [[ ${forwarding_type_num} == "3" ]]; then
		forwarding_type="TCP+UDP"
	else
		forwarding_type="TCP+UDP"
	fi
}
Set_Config(){
	Set_forwarding_port
	Set_forwarding_ip
	Set_local_port
	Set_local_ip
	Set_forwarding_type
	echo && echo -e "——————————————————————————————
	請檢查 iptables 埠轉發規則設定是否有誤 !\n
	本機監聽埠    : ${Green_font_prefix}${local_port}${Font_color_suffix}
	伺服器 IP\t: ${Green_font_prefix}${local_ip}${Font_color_suffix}\n
	欲轉發的埠    : ${Green_font_prefix}${forwarding_port}${Font_color_suffix}
	欲轉發 IP\t: ${Green_font_prefix}${forwarding_ip}${Font_color_suffix}
	轉發類型\t: ${Green_font_prefix}${forwarding_type}${Font_color_suffix}
——————————————————————————————\n"
	stty erase '^H' && read -p "請按任意鍵繼續，如有設定錯誤請使用 Ctrl+C 退出。" var
}
Add_forwarding(){
	check_iptables
	Set_Config
	local_port=$(echo ${local_port} | sed 's/-/:/g')
	forwarding_port_1=$(echo ${forwarding_port} | sed 's/-/:/g')
	if [[ ${forwarding_type} == "TCP" ]]; then
		Add_iptables "tcp"
	elif [[ ${forwarding_type} == "UDP" ]]; then
		Add_iptables "udp"
	elif [[ ${forwarding_type} == "TCP+UDP" ]]; then
		Add_iptables "tcp"
		Add_iptables "udp"
	fi
	Save_iptables
	clear && echo && echo -e "——————————————————————————————
	iptables 埠轉發規則設定完成 !\n
	本機監聽埠    : ${Green_font_prefix}${local_port}${Font_color_suffix}
	伺服器 IP\t: ${Green_font_prefix}${local_ip}${Font_color_suffix}\n
	欲轉發的埠    : ${Green_font_prefix}${forwarding_port_1}${Font_color_suffix}
	欲轉發 IP\t: ${Green_font_prefix}${forwarding_ip}${Font_color_suffix}
	轉發類型\t: ${Green_font_prefix}${forwarding_type}${Font_color_suffix}
——————————————————————————————\n"
}
View_forwarding(){
	check_iptables
	forwarding_text=$(iptables -t nat -vnL PREROUTING|tail -n +3)
	[[ -z ${forwarding_text} ]] && echo -e "${Error} 沒有發現 iptables 埠轉發規則，請檢查 !" && exit 1
	forwarding_total=$(echo -e "${forwarding_text}"|wc -l)
	forwarding_list_all=""
	for((integer = 1; integer <= ${forwarding_total}; integer++))
	do
		forwarding_type=$(echo -e "${forwarding_text}"|awk '{print $4}'|sed -n "${integer}p")
		forwarding_listen=$(echo -e "${forwarding_text}"|awk '{print $11}'|sed -n "${integer}p"|awk -F "dpt:" '{print $2}')
		[[ -z ${forwarding_listen} ]] && forwarding_listen=$(echo -e "${forwarding_text}"| awk '{print $11}'|sed -n "${integer}p"|awk -F "dpts:" '{print $2}')
		forwarding_fork=$(echo -e "${forwarding_text}"| awk '{print $12}'|sed -n "${integer}p"|awk -F "to:" '{print $2}')
		forwarding_list_all=${forwarding_list_all}"${Green_font_prefix}"${integer}".${Font_color_suffix} 類型: ${Green_font_prefix}"${forwarding_type}"${Font_color_suffix} 監聽埠: ${Red_font_prefix}"${forwarding_listen}"${Font_color_suffix} 轉發IP和埠: ${Red_font_prefix}"${forwarding_fork}"${Font_color_suffix}\n"
	done
	echo && echo -e "目前有 ${Green_background_prefix} "${forwarding_total}" ${Font_color_suffix} 個 iptables 埠轉發規則。"
	echo -e ${forwarding_list_all}
}
Del_forwarding(){
	check_iptables
	while true
	do
	View_forwarding
	stty erase '^H' && read -p "請輸入數字 來選擇要刪除的 iptables 埠轉發規則(預設回車取消):" Del_forwarding_num
	[[ -z "${Del_forwarding_num}" ]] && Del_forwarding_num="0"
	expr ${Del_forwarding_num} + 0 &>/dev/null
	if [[ $? -eq 0 ]]; then
		if [[ ${Del_forwarding_num} -ge 1 ]] && [[ ${Del_forwarding_num} -le ${forwarding_total} ]]; then
			forwarding_type=$(echo -e "${forwarding_text}"| awk '{print $4}' | sed -n "${Del_forwarding_num}p")
			forwarding_listen=$(echo -e "${forwarding_text}"| awk '{print $11}' | sed -n "${Del_forwarding_num}p" | awk -F "dpt:" '{print $2}' | sed 's/-/:/g')
			[[ -z ${forwarding_listen} ]] && forwarding_listen=$(echo -e "${forwarding_text}"| awk '{print $11}' |sed -n "${Del_forwarding_num}p" | awk -F "dpts:" '{print $2}')
			Del_iptables "${forwarding_type}" "${Del_forwarding_num}"
			Save_iptables
			echo && echo -e "${Info} iptables 埠轉發規則刪除完成 !" && echo
		else
			echo -e "${Error} 請輸入正確的數位 !"
		fi
	else
		break && echo "取消..."
	fi
	done
}
Uninstall_forwarding(){
	check_iptables
	echo -e "確定要清空 iptables 所有埠轉發規則 ? [y/N]"
	stty erase '^H' && read -p "(預設: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		forwarding_text=$(iptables -t nat -vnL PREROUTING|tail -n +3)
		[[ -z ${forwarding_text} ]] && echo -e "${Error} 沒有發現 iptables 埠轉發規則，請檢查 !" && exit 1
		forwarding_total=$(echo -e "${forwarding_text}"|wc -l)
		for((integer = 1; integer <= ${forwarding_total}; integer++))
		do
			forwarding_type=$(echo -e "${forwarding_text}"|awk '{print $4}'|sed -n "${integer}p")
			forwarding_listen=$(echo -e "${forwarding_text}"|awk '{print $11}'|sed -n "${integer}p"|awk -F "dpt:" '{print $2}')
			[[ -z ${forwarding_listen} ]] && forwarding_listen=$(echo -e "${forwarding_text}"| awk '{print $11}'|sed -n "${integer}p"|awk -F "dpts:" '{print $2}')
			# echo -e "${forwarding_text} ${forwarding_type} ${forwarding_listen}"
			Del_iptables "${forwarding_type}" "${integer}"
		done
		Save_iptables
		echo && echo -e "${Info} iptables 已清空 所有埠轉發規則 !" && echo
	else
		echo && echo "清空已取消..." && echo
	fi
}
Add_iptables(){
	iptables -t nat -A PREROUTING -p "$1" --dport "${local_port}" -j DNAT --to-destination "${forwarding_ip}":"${forwarding_port}"
	iptables -t nat -A POSTROUTING -p "$1" -d "${forwarding_ip}" --dport "${forwarding_port_1}" -j SNAT --to-source "${local_ip}"
	echo "iptables -t nat -A PREROUTING -p $1 --dport ${local_port} -j DNAT --to-destination ${forwarding_ip}:${forwarding_port}"
	echo "iptables -t nat -A POSTROUTING -p $1 -d ${forwarding_ip} --dport ${forwarding_port_1} -j SNAT --to-source ${local_ip}"
	echo "${local_port}"
	iptables -I INPUT -m state --state NEW -m "$1" -p "$1" --dport "${local_port}" -j ACCEPT
}
Del_iptables(){
	iptables -t nat -D POSTROUTING "$2"
	iptables -t nat -D PREROUTING "$2"
	iptables -D INPUT -m state --state NEW -m "$1" -p "$1" --dport "${forwarding_listen}" -j ACCEPT
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}
Set_iptables(){
	echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
	sysctl -p
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
	sh_new_ver=$(wget --no-check-certificate -qO- "https://raw.githubusercontent.com/david082321/doubi/master/iptables-pf.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 檢測最新版本失敗 !" && exit 1
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "發現新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
		stty erase '^H' && read -p "(預設: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			wget -N --no-check-certificate https://raw.githubusercontent.com/david082321/doubi/master/iptables-pf.sh && chmod +x iptables-pf.sh
			echo -e "腳本已更新為最新版本[ ${sh_new_ver} ] !"
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo -e "目前已是最新版本[ ${sh_new_ver} ] !"
	fi
}
check_sys
echo && echo -e " iptables 埠轉發一鍵管理腳本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/wlzy-20 --
  
 ${Green_font_prefix}0.${Font_color_suffix} 升級腳本
————————————
 ${Green_font_prefix}1.${Font_color_suffix} 安裝 iptables
 ${Green_font_prefix}2.${Font_color_suffix} 清空 iptables 埠轉發
————————————
 ${Green_font_prefix}3.${Font_color_suffix} 查看 iptables 埠轉發
 ${Green_font_prefix}4.${Font_color_suffix} 添加 iptables 埠轉發
 ${Green_font_prefix}5.${Font_color_suffix} 刪除 iptables 埠轉發
————————————
注意：初次使用前請請務必執行 ${Green_font_prefix}1. 安裝 iptables${Font_color_suffix}(不僅僅是安裝)" && echo
stty erase '^H' && read -p " 請輸入數字 [0-5]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	install_iptables
	;;
	2)
	Uninstall_forwarding
	;;
	3)
	View_forwarding
	;;
	4)
	Add_forwarding
	;;
	5)
	Del_forwarding
	;;
	*)
	echo "請輸入正確數字 [0-5]"
	;;
esac
