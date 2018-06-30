#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: DowsDNS
#	Version: 1.0.7
#	Author: Toyo
#	Blog: https://doub.io/dowsdns-jc3/
#=================================================

sh_ver="1.0.7"
file="/usr/local/dowsDNS"
dowsdns_conf="/usr/local/dowsDNS/conf/config.json"
dowsdns_data="/usr/local/dowsDNS/conf/hosts_repository_config.json"
dowsdns_wrcd="/usr/local/dowsDNS/data/wrcd.json"
dowsdns_log="/tmp/dowsdns.log"

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
	bit=`uname -m`
}
check_installed_status(){
	[[ ! -e ${file} ]] && echo -e "${Error} DowsDNS 沒有安裝，請檢查 !" && exit 1
}
check_pid(){
	PID=`ps -ef| grep "python start.py"| grep -v grep| grep -v ".sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
Download_dowsdns(){
	cd "/usr/local"
	wget -N --no-check-certificate "https://github.com/david082321/dowsDNS/archive/beta.zip"
	[[ ! -e "dowsDNS.zip" ]] && echo -e "${Error} DowsDNS 下載失敗 !" && exit 1
	unzip dowsDNS.zip && rm -rf dowsDNS.zip
	[[ ! -e "dowsDNS-master" ]] && echo -e "${Error} DowsDNS 解壓失敗 !" && exit 1
	mv dowsDNS-master dowsDNS
	[[ ! -e "dowsDNS" ]] && echo -e "${Error} DowsDNS 資料夾重新命名失敗 !" && rm -rf dowsDNS-master && exit 1
}
Service_dowsdns(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate "https://softs.loan/Bash/other/dowsdns_centos" -O /etc/init.d/dowsdns; then
			echo -e "${Error} DowsDNS 服務管理腳本下載失敗 !" && exit 1
		fi
		chmod +x /etc/init.d/dowsdns
		chkconfig --add dowsdns
		chkconfig dowsdns on
	else
		if ! wget --no-check-certificate "https://softs.loan/Bash/other/dowsdns_debian" -O /etc/init.d/dowsdns; then
			echo -e "${Error} DowsDNS 服務管理腳本下載失敗 !" && exit 1
		fi
		chmod +x /etc/init.d/dowsdns
		update-rc.d -f dowsdns defaults
	fi
	echo -e "${Info} DowsDNS 服務管理腳本下載完成 !"
}
Installation_dependency(){
	python_status=$(python --help)
	if [[ ${release} == "centos" ]]; then
		yum update
		if [[ -z ${python_status} ]]; then
			yum install -y python unzip
		else
			yum install -y unzip
		fi
	else
		apt-get update
		if [[ -z ${python_status} ]]; then
			apt-get install -y python unzip
		else
			apt-get install -y unzip
		fi
	fi
}
Write_config(){
	cat > ${dowsdns_conf}<<-EOF
{
	"Remote_dns_server":"${dd_remote_dns_server}",
	"Remote_dns_port":${dd_remote_dns_port},
	"Rpz_json_path":"./data/rpz.json",
	"Local_dns_server":"${dd_local_dns_server}",
	"Local_dns_port":${dd_local_dns_port},
	"sni_proxy_on":${dd_sni_proxy_on},
	"Public_Server":${public_server},
	"sni_proxy_ip":"${dd_sni_proxy_ip}"
}
EOF

}
Read_config(){
	[[ ! -e ${dowsdns_conf} ]] && echo -e "${Error} DowsDNS 設定檔案不存在 !" && exit 1
	remote_dns_server=`cat ${dowsdns_conf}|grep "Remote_dns_server"|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/'`
	remote_dns_port=`cat ${dowsdns_conf}|grep "Remote_dns_port"|sed -r 's/.*:(.+),.*/\1/'`
	local_dns_server=`cat ${dowsdns_conf}|grep "Local_dns_server"|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/'`
	local_dns_port=`cat ${dowsdns_conf}|grep "Local_dns_port"|sed -r 's/.*:(.+),.*/\1/'`
	sni_proxy_ip=`cat ${dowsdns_conf}|grep "sni_proxy_ip"|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/'`
}
Read_wrcd(){
	[[ ! -e ${dowsdns_wrcd} ]] && echo -e "${Error} DowsDNS 泛域名解析 設定檔案不存在 !" && exit 1
	wrcd_json=$(cat -n ${dowsdns_wrcd}|sed '$d;1d;s/\"//g;s/,//g')
	wrcd_json_num=$(echo -e "${wrcd_json}"|wc -l)
	wrcd_json_num=$(expr $wrcd_json_num + 1)
	echo -e "目前DowsDNS 泛域名解析設定(不要問我為什麼是從 2 開始)：\n"
	echo -e "${wrcd_json}\n"
}
Set_remote_dns_server(){
	echo "請輸入 DowsDNS 遠程(上游)DNS解析伺服器IP"
	stty erase '^H' && read -p "(預設: 114.114.114.114):" dd_remote_dns_server
	[[ -z "${dd_remote_dns_server}" ]] && dd_remote_dns_server="114.114.114.114"
	echo
}
Set_remote_dns_port(){
	while true
		do
		echo -e "請輸入 DowsDNS 遠程(上游)DNS解析伺服器埠 [1-65535]"
		stty erase '^H' && read -p "(預設: 53):" dd_remote_dns_port
		[[ -z "$dd_remote_dns_port" ]] && dd_remote_dns_port="53"
		expr ${dd_remote_dns_port} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${dd_remote_dns_port} -ge 1 ]] && [[ ${dd_remote_dns_port} -le 65535 ]]; then
				echo
				break
			else
				echo "輸入錯誤, 請輸入正確的埠。"
			fi
		else
			echo "輸入錯誤, 請輸入正確的埠。"
		fi
	done
}
Set_remote_dns(){
	echo -e "請選擇並輸入 DowsDNS 的遠程(上游)DNS解析伺服器
 說明：即一些DowsDNS沒有指定的域名都由上游DNS解析，比如百度什麼的。
 
 ${Green_font_prefix}1.${Font_color_suffix} 114.114.114.114 53
 ${Green_font_prefix}2.${Font_color_suffix} 8.8.8.8 53
 ${Green_font_prefix}3.${Font_color_suffix} 208.67.222.222 53
 ${Green_font_prefix}4.${Font_color_suffix} 208.67.222.222 5353
 ${Green_font_prefix}5.${Font_color_suffix} 自訂輸入" && echo
	stty erase '^H' && read -p "(預設: 1. 114.114.114.114 53):" dd_remote_dns
	[[ -z "${dd_remote_dns}" ]] && dd_remote_dns="1"
	if [[ ${dd_remote_dns} == "1" ]]; then
		dd_remote_dns_server="114.114.114.114"
		dd_remote_dns_port="53"
	elif [[ ${dd_remote_dns} == "2" ]]; then
		dd_remote_dns_server="8.8.8.8"
		dd_remote_dns_port="53"
	elif [[ ${dd_remote_dns} == "3" ]]; then
		dd_remote_dns_server="208.67.222.222"
		dd_remote_dns_port="53"
	elif [[ ${dd_remote_dns} == "4" ]]; then
		dd_remote_dns_server="208.67.222.222"
		dd_remote_dns_port="5353"
	elif [[ ${dd_remote_dns} == "5" ]]; then
		echo
		Set_remote_dns_server
		Set_remote_dns_port
	else
		dd_remote_dns_server="114.114.114.114"
		dd_remote_dns_port="53"
	fi
	echo && echo "	================================================"
	echo -e "	遠程(上游)DNS解析伺服器 IP :\t ${Red_background_prefix} ${dd_remote_dns_server} ${Font_color_suffix}
	遠程(上游)DNS解析伺服器 埠 :\t ${Red_background_prefix} ${dd_remote_dns_port} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_local_dns_server(){
	echo -e "請選擇並輸入 DowsDNS 的本機監聽方式
 ${Green_font_prefix}1.${Font_color_suffix} 127.0.0.1 (只允許本機和區域網路設備訪問)
 ${Green_font_prefix}2.${Font_color_suffix} 0.0.0.0 (允許外網訪問)" && echo
	stty erase '^H' && read -p "(預設: 2. 0.0.0.0):" dd_local_dns_server
	[[ -z "${dd_local_dns_server}" ]] && dd_local_dns_server="2"
	if [[ ${dd_local_dns_server} == "1" ]]; then
		dd_local_dns_server="127.0.0.1"
		public_server="false"
	elif [[ ${dd_local_dns_server} == "2" ]]; then
		dd_local_dns_server="0.0.0.0"
		public_server="true"
	else
		dd_local_dns_server="0.0.0.0"
		public_server="true"
	fi
	echo && echo "	================================================"
	echo -e "	本機監聽方式: ${Red_background_prefix} ${dd_local_dns_server} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_local_dns_port(){
	while true
		do
		echo -e "請輸入 DowsDNS 監聽埠 [1-65535]
 注意：大部分設備是不支援設定 非53埠的DNS伺服器的，所以非必須請直接回車預設使用 53埠。" && echo
		stty erase '^H' && read -p "(預設: 53):" dd_local_dns_port
		[[ -z "$dd_local_dns_port" ]] && dd_local_dns_port="53"
		expr ${dd_local_dns_port} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${dd_local_dns_port} -ge 1 ]] && [[ ${dd_local_dns_port} -le 65535 ]]; then
				echo && echo "	================================================"
				echo -e "	監聽埠 : ${Red_background_prefix} ${dd_local_dns_port} ${Font_color_suffix}"
				echo "	================================================" && echo
				break
			else
				echo "輸入錯誤, 請輸入正確的埠。"
			fi
		else
			echo "輸入錯誤, 請輸入正確的埠。"
		fi
		done
}
Set_sni_proxy_on(){
	echo "是否開啟 DowsDNS SNI代理功能？[y/N]
 注意：開啟此功能後，任何自訂設置的 hosts或泛域名解析(包括DowsDNS自帶的)，都指向設置的SNI代理IP，如果你沒有SNI代理IP，請輸入 N !"
	stty erase '^H' && read -p "(預設: N 關閉):" dd_sni_proxy_on
	[[ -z "${dd_sni_proxy_on}" ]] && dd_sni_proxy_on="n"
	if [[ ${dd_sni_proxy_on} == [Yy] ]]; then
		dd_sni_proxy_on="true"
	else
		dd_sni_proxy_on="false"
	fi
	echo && echo "	================================================"
	echo -e "	SNI代理開關 : ${Red_background_prefix} ${dd_sni_proxy_on} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_sni_proxy_ip(){
	ddd_sni_proxy_ip=$(wget --no-check-certificate -t2 -T4 -qO- "https://raw.githubusercontent.com/dowsnature/dowsDNS/master/conf/config.json"|grep "sni_proxy_ip"|awk -F ":" '{print $NF}'|sed -r 's/.*\"(.+)\".*/\1/')
	[[ -z ${ddd_sni_proxy_ip} ]] && ddd_sni_proxy_ip="219.76.4.3"
	echo "請輸入 DowsDNS SNI代理 IP（如果沒有就直接回車）"
	stty erase '^H' && read -p "(預設: ${ddd_sni_proxy_ip}):" dd_sni_proxy_ip
	[[ -z "${dd_sni_proxy_ip}" ]] && dd_sni_proxy_ip="${ddd_sni_proxy_ip}"
	echo && echo "	================================================"
	echo -e "	SNI代理 IP : ${Red_background_prefix} ${dd_sni_proxy_ip} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_conf(){
	Set_remote_dns
	Set_local_dns_server
	Set_local_dns_port
	Set_sni_proxy_on
	Set_sni_proxy_ip
}
Set_dowsdns_basis(){
	check_installed_status
	Set_conf
	Read_config
	Del_iptables
	Write_config
	Add_iptables
	Save_iptables
	Restart_dowsdns
}
Set_wrcd_name(){
	echo "請輸入 DowsDNS 要添加/修改的域名(子域名或泛域名)
 注意：假如你想要 youtube.com 及其二級域名全部指向 指定的IP，那麼你需要添加 *.youtube.com 和 youtube.com 這兩個域名解析才有效。
 這意味著 *.youtube.com 僅代表如 www.youtube.com xxx.youtube.com 這樣的二級域名，而不能代表一級域名(頂級域名) youtube.com ！"
	stty erase '^H' && read -p "(預設回車取消):" wrcd_name
	[[ -z "${wrcd_name}" ]] && echo "已取消..." && exit 0
	echo
}
Set_wrcd_name_1(){
	echo "檢測到目前添加的域名為 泛域名，是否自動添加 上級域名(如頂級域名，就是上面範例說的 youtube.com) [Y/n]"
	stty erase '^H' && read -p "(預設: Y 添加):" wrcd_name_1
	[[ -z "${wrcd_name_1}" ]] && wrcd_name_1="y"
	if [[ ${wrcd_name_1} == [Yy] ]]; then
		wrcd_name_1=$(echo -e "${wrcd_name}"|cut -c 3-100)
		echo -e "檢測到 上級域名為 : ${Red_font_prefix}${wrcd_name_1}${Font_color_suffix}"
	else
		wrcd_name_1=""
		echo "已取消...繼續..."
	fi
	echo
}
Set_wrcd_ip(){
	echo "請輸入 DowsDNS 剛才添加/修改的域名要指向的IP
 注意：如果你開啟了 SNI代理功能(config.json)，那麼你這裡設置的自訂泛域名解析都會被 SNI代理功能的SNI代理IP設定所覆蓋，也就是統一指向 SNI代理的IP，這裡的IP設定就沒意義了。"
	stty erase '^H' && read -p "(預設回車取消):" wrcd_ip
	[[ -z "${wrcd_ip}" ]] && echo "已取消..." && exit 0
	echo
}
Set_dowsdns_wrcd(){
	check_installed_status
	echo && echo -e "你要做什麼？
 ${Green_font_prefix}0.${Font_color_suffix} 查看 泛域名解析列表
 
 ${Green_font_prefix}1.${Font_color_suffix} 添加 泛域名解析
 ${Green_font_prefix}2.${Font_color_suffix} 刪除 泛域名解析
 ${Green_font_prefix}3.${Font_color_suffix} 修改 泛域名解析" && echo
	stty erase '^H' && read -p "(預設: 取消):" wrcd_modify
	[[ -z "${wrcd_modify}" ]] && echo "已取消..." && exit 1
	if [[ ${wrcd_modify} == "0" ]]; then
		Read_wrcd
	elif [[ ${wrcd_modify} == "1" ]]; then
		Add_wrcd
	elif [[ ${wrcd_modify} == "2" ]]; then
		Del_wrcd
	elif [[ ${wrcd_modify} == "3" ]]; then
		Modify_wrcd
	else
		echo -e "${Error} 請輸入正確的數位 [0-3]" && exit 1
	fi
}
Add_wrcd(){
	while true
		do
		Set_wrcd_name
		[[ $(echo -e "${wrcd_name}"|cut -c 1-2) == "*." ]] && Set_wrcd_name_1
		Set_wrcd_ip
		sed -i "2 i \"${wrcd_name}\":\"${wrcd_ip}\"," ${dowsdns_wrcd}
		if [[ $? == "0" ]]; then
			echo -e "${Info} 添加泛域名解析 成功 [${wrcd_name} : ${wrcd_ip}]"
		else
			echo -e "${Error} 添加泛域名解析 失敗！" && exit 0
		fi
		if [[ ! -z ${wrcd_name_1} ]]; then
			sed -i "2 i \"${wrcd_name_1}\":\"${wrcd_ip}\"," ${dowsdns_wrcd}
			if [[ $? == "0" ]]; then
				echo -e "${Info} 添加泛域名解析 成功 [${wrcd_name_1} : ${wrcd_ip}]"
			else
				echo -e "${Error} 添加泛域名解析 失敗！" && exit 0
			fi
		fi
		echo && echo "是否繼續添加 泛域名解析？[Y/n]"
		stty erase '^H' && read -p "(預設: Y 繼續添加):" wrcd_add_1
		[[ -z "${wrcd_add_1}" ]] && wrcd_add_1="y"
		if [[ ${wrcd_add_1} == [Yy] ]]; then
			continue
		else
			break
		fi
	done
	echo -e "${Info} 重啟 dowsDNS中..."
	Restart_dowsdns
}
Del_wrcd(){
	while true
		do
		Read_wrcd
		echo "請根據上面的列表選擇你要刪除的 泛域名解析 序號數字 [ 2-${wrcd_json_num} ]"
		stty erase '^H' && read -p "(預設回車取消):" del_wrcd_num
		[[ -z "$del_wrcd_num" ]] && echo "已取消..." && exit 0
		expr ${del_wrcd_num} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${del_wrcd_num} -ge 2 ]] && [[ ${del_wrcd_num} -le ${wrcd_json_num} ]]; then
				wrcd_text=$(cat ${dowsdns_wrcd}|sed -n "${del_wrcd_num}p")
				wrcd_name=$(echo -e "${wrcd_text}"|sed 's/\"//g;s/,//g'|awk -F ":" '{print $1}')
				wrcd_ip=$(echo -e "${wrcd_text}"|sed 's/\"//g;s/,//g'|awk -F ":" '{print $2}')
				del_wrcd_determine=$(echo ${wrcd_text:((${#wrcd_text} - 1))})
				if [[ ${del_wrcd_num} == ${wrcd_json_num} ]]; then
					del_wrcd_determine_num=$(expr $del_wrcd_num - 1)
					sed -i "${del_wrcd_determine_num}s/,//g" ${dowsdns_wrcd}
				fi
				sed -i "${del_wrcd_num}d" ${dowsdns_wrcd}
				if [[ $? == "0" ]]; then
					echo -e "${Info} 刪除泛域名解析 成功 [${wrcd_name} : ${wrcd_ip}]"
				else
					echo -e "${Error} 刪除泛域名解析 失敗！" && exit 0
				fi
				echo && echo "是否繼續刪除 泛域名解析？[Y/n]"
				stty erase '^H' && read -p "(預設: Y 繼續刪除):" wrcd_del_1
				[[ -z "${wrcd_del_1}" ]] && wrcd_del_1="y"
				if [[ ${wrcd_del_1} == [Yy] ]]; then
					continue
				else
					break
				fi
			else
				echo "輸入錯誤, 請輸入正確的數位。"
			fi
		else
			echo "輸入錯誤, 請輸入正確的數位。"
		fi
	done
	echo -e "${Info} 重啟 dowsDNS中..."
	Restart_dowsdns
}
Modify_wrcd(){
	while true
		do
		Read_wrcd
		echo "請根據上面的列表選擇你要修改的 泛域名解析 序號數字 [ 2-${wrcd_json_num} ]"
		stty erase '^H' && read -p "(預設回車取消):" modify_wrcd_num
		[[ -z "$modify_wrcd_num" ]] && echo "已取消..." && exit 0
		expr ${modify_wrcd_num} + 0 &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${modify_wrcd_num} -ge 2 ]] && [[ ${modify_wrcd_num} -le ${wrcd_json_num} ]]; then
				wrcd_name_now=$(cat ${dowsdns_wrcd}|sed -n "${modify_wrcd_num}p"|sed 's/\"//g;s/,//g'|awk -F ":" '{print $1}')
				wrcd_ip_now=$(cat ${dowsdns_wrcd}|sed -n "${modify_wrcd_num}p"|sed 's/\"//g;s/,//g'|awk -F ":" '{print $2}')
				echo
				Set_wrcd_name
				Set_wrcd_ip
				sed -i "${modify_wrcd_num}d" ${dowsdns_wrcd}
				sed -i "${modify_wrcd_num} i \"${wrcd_name}\":\"${wrcd_ip}\"," ${dowsdns_wrcd}
				#sed -i "s/\"${wrcd_name_now_1}\":\"${wrcd_ip_now}\"/\"${wrcd_name_1}\":\"${wrcd_ip}\"/g" ${dowsdns_wrcd}
				if [[ $? == "0" ]]; then
					echo -e "${Info} 修改泛域名解析 成功 [舊 ${wrcd_name_now} : ${wrcd_ip_now} , 新 ${wrcd_name} : ${wrcd_ip}]"
				else
					echo -e "${Error} 修改泛域名解析 失敗！" && exit 0
				fi
				break
			else
				echo "輸入錯誤, 請輸入正確的數位。"
			fi
		else
			echo "輸入錯誤, 請輸入正確的數位。"
		fi
	done
	echo -e "${Info} 重啟 dowsDNS中..."
	Restart_dowsdns
}
Install_dowsdns(){
	[[ -e ${file} ]] && echo -e "${Error} 檢測到 DowsDNS 已安裝 !" && exit 1
	check_sys
	echo -e "${Info} 開始設定 使用者設定..."
	Set_conf
	echo -e "${Info} 開始安裝/設定 依賴..."
	Installation_dependency
	echo -e "${Info} 開始下載/安裝..."
	Download_dowsdns
	echo -e "${Info} 開始下載/安裝 服務腳本(init)..."
	Service_dowsdns
	echo -e "${Info} 開始寫入 設定檔案..."
	Write_config
	echo -e "${Info} 開始設定 iptables防火牆..."
	Set_iptables
	echo -e "${Info} 開始添加 iptables防火牆規則..."
	Add_iptables
	echo -e "${Info} 開始儲存 iptables防火牆規則..."
	Save_iptables
	echo -e "${Info} 所有步驟 安裝完畢，開始啟動..."
	Start_dowsdns
}
Start_dowsdns(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} DowsDNS 正在執行，請檢查 !" && exit 1
	/etc/init.d/dowsdns start
}
Stop_dowsdns(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} DowsDNS 沒有執行，請檢查 !" && exit 1
	/etc/init.d/dowsdns stop
}
Restart_dowsdns(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/dowsdns stop
	/etc/init.d/dowsdns start
}
Update_dowsdns(){
	check_installed_status
	check_sys
	cd ${file}
	python update.py
}
Uninstall_dowsdns(){
	check_installed_status
	echo "確定要移除 DowsDNS ? (y/N)"
	echo
	stty erase '^H' && read -p "(預設: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config
		Del_iptables
		rm -rf ${file} && rm -rf /etc/init.d/dowsdns
		if [[ ${release} = "centos" ]]; then
			chkconfig --del dowsdns
		else
			update-rc.d -f dowsdns remove
		fi
		echo && echo "DowsDNS 移除完成 !" && echo
	else
		echo && echo "移除已取消..." && echo
	fi
}
View_dowsdns(){
	check_installed_status
	Read_config
	if [[ ${local_dns_server} == "127.0.0.1" ]]; then
		ip="${local_dns_server} "
	else
		ip=`wget -qO- -t1 -T2 members.3322.org/dyndns/getip`
		[[ -z ${ip} ]] && ip="VPS_IP"
	fi
	clear && echo "————————————————" && echo
	echo -e " 請在你的設備中設定DNS伺服器為：
 IP : ${Green_font_prefix}${ip}${Font_color_suffix} ,埠 : ${Green_font_prefix}${local_dns_port}${Font_color_suffix}
 
 注意：如果設備中沒有 DNS埠設定選項，那麼就只能使用預設的 53 埠"
	echo && echo "————————————————"
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${dd_local_dns_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${dd_local_dns_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${local_dns_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${local_dns_port} -j ACCEPT
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
View_Log(){
	[[ ! -e ${dowsdns_log} ]] && echo -e "${Error} dowsDNS 日誌檔案不存在 !" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 終止查看日誌" && echo
	tail -f ${dowsdns_log}
}
Update_Shell(){
	echo -e "目前版本為 [ ${sh_ver} ]，開始檢測最新版本..."
	sh_new_ver=$(wget --no-check-certificate -qO- softs.loan/Bash/dowsdns.sh|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1)
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 檢測最新版本失敗 !" && exit 0
	if [[ ${sh_new_ver} != ${sh_ver} ]]; then
		echo -e "發現新版本[ ${sh_new_ver} ]，是否更新？[Y/n]"
		stty erase '^H' && read -p "(預設: y):" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ ${yn} == [Yy] ]]; then
			wget -N --no-check-certificate "https://softs.loan/Bash/dowsdns.sh" && chmod +x dowsdns.sh
			echo -e "腳本已更新為最新版本[ ${sh_new_ver} ] !"
		else
			echo && echo "	已取消..." && echo
		fi
	else
		echo -e "目前已是最新版本[ ${sh_new_ver} ] !"
	fi
}
echo && echo -e "  DowsDNS 一鍵安裝管理腳本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/dowsdns-jc3 --
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升級腳本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安裝 DowsDNS
 ${Green_font_prefix} 2.${Font_color_suffix} 升級 DowsDNS
 ${Green_font_prefix} 3.${Font_color_suffix} 移除 DowsDNS
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 啟動 DowsDNS
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 DowsDNS
 ${Green_font_prefix} 6.${Font_color_suffix} 重啟 DowsDNS
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 設定 DowsDNS 基礎設定
 ${Green_font_prefix} 8.${Font_color_suffix} 設定 DowsDNS 泛域名解析設定
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 DowsDNS 訊息
 ${Green_font_prefix}10.${Font_color_suffix} 查看 DowsDNS 日誌
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
	Install_dowsdns
	;;
	2)
	Update_dowsdns
	;;
	3)
	Uninstall_dowsdns
	;;
	4)
	Start_dowsdns
	;;
	5)
	Stop_dowsdns
	;;
	6)
	Restart_dowsdns
	;;
	7)
	Set_dowsdns_basis
	;;
	8)
	Set_dowsdns_wrcd
	;;
	9)
	View_dowsdns
	;;
	10)
	View_Log
	;;
	*)
	echo "請輸入正確數字 [0-10]"
	;;
esac
